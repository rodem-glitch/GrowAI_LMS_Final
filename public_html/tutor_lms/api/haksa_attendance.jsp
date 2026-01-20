<%@ page pageEncoding="utf-8" %><%@ page import="org.json.*" %><%@ include file="init.jsp" %><%!
// 왜: 학사 차시 기간/출석 판정은 문자열 날짜가 많아, 안전한 파싱 유틸이 필요합니다.
private String onlyDigits(String value) {
	if(value == null) return "";
	return value.replaceAll("[^0-9]", "");
}

private String buildDateTime(String date, String time, boolean isStart) {
	String ymd = onlyDigits(date);
	if(ymd.length() >= 8) ymd = ymd.substring(0, 8);
	if(ymd.length() != 8) return "";

	String hm = onlyDigits(time);
	if(hm.length() >= 4) hm = hm.substring(0, 4);
	if(hm.length() != 4) hm = isStart ? "0000" : "2359";

	return ymd + hm + (isStart ? "00" : "59");
}

private boolean isWithinPeriod(String target, String start, String end) {
	if("".equals(start) || "".equals(end)) return true;
	if("".equals(target)) return false;
	return start.compareTo(target) <= 0 && end.compareTo(target) >= 0;
}

private String safeDate(String... candidates) {
	for(String c : candidates) {
		if(c != null && c.length() >= 8) return c;
	}
	return "";
}

private String joinInts(java.util.ArrayList<Integer> list) {
	if(list == null || list.size() == 0) return "0";
	StringBuilder sb = new StringBuilder();
	for(int i = 0; i < list.size(); i++) {
		if(i > 0) sb.append(",");
		sb.append(list.get(i));
	}
	return sb.toString();
}
%><%

//왜 필요한가:
//- 학사 과목은 주차/차시 기준으로 "동영상/시험/과제 제출 완료"를 묶어 출석을 판정합니다.
//- 제출만 완료로 처리하며, 차시 수강기간(날짜+시간) 안에 완료되었는지 확인합니다.

String courseCode = m.rs("course_code");
String openYear = m.rs("open_year");
String openTerm = m.rs("open_term");
String bunbanCode = m.rs("bunban_code");
String groupCode = m.rs("group_code");
String sessionId = m.rs("session_id");
int courseId = m.ri("course_id");

if("".equals(courseCode) || "".equals(openYear) || "".equals(openTerm) || "".equals(bunbanCode) || "".equals(groupCode) || "".equals(sessionId)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "학사 과목 키(course_code/open_year/open_term/bunban_code/group_code)와 session_id가 필요합니다.");
	result.print();
	return;
}

PolyCourseSettingDao setting = new PolyCourseSettingDao();
DataSet info = setting.find(
	"site_id = " + siteId
	+ " AND course_code = ? AND open_year = ? AND open_term = ? AND bunban_code = ? AND group_code = ?"
	+ " AND status != -1"
	, new Object[] { courseCode, openYear, openTerm, bunbanCode, groupCode }
);

String curriculumJson = "";
if(info.next()) curriculumJson = info.s("curriculum_json");

if("".equals(curriculumJson)) {
	result.put("rst_code", "0000");
	result.put("rst_message", "성공");
	result.put("rst_data", new DataSet());
	result.print();
	return;
}

// 과정ID 매핑(없으면 학사키 기반으로 재검색)
if(courseId <= 0) {
	try {
		String haksaCourseKey = courseCode + "_" + openYear + "_" + openTerm + "_" + bunbanCode + "_" + groupCode;
		String haksaCourseCd = m.md5(haksaCourseKey);
		if(haksaCourseCd != null && haksaCourseCd.length() > 20) haksaCourseCd = haksaCourseCd.substring(0, 20);
		if(haksaCourseCd == null) haksaCourseCd = "";

		String safeHaksaCourseKey = m.replace(haksaCourseKey, "'", "''");
		String safeHaksaCourseCd = m.replace(haksaCourseCd, "'", "''");

		CourseDao course = new CourseDao();
		DataSet mappedCourse = course.find(
			"site_id = " + siteId
			+ " AND (course_cd = '" + safeHaksaCourseCd + "' OR course_cd = '" + safeHaksaCourseKey + "' OR etc1 = '" + safeHaksaCourseKey + "')"
			+ " AND status != -1"
		);
		if(mappedCourse.next()) courseId = mappedCourse.i("id");
	} catch(Exception ignore) {}
}

if(courseId <= 0) {
	result.put("rst_code", "4040");
	result.put("rst_message", "매핑된 과정ID를 찾지 못했습니다.");
	result.print();
	return;
}

JSONArray weeks = new JSONArray(curriculumJson);
JSONObject targetSession = null;
int sessionNo = 0;
int seq = 0;

for(int i = 0; i < weeks.length(); i++) {
	JSONObject w = weeks.optJSONObject(i);
	if(w == null) continue;
	JSONArray sessions = w.optJSONArray("sessions");
	if(sessions == null) continue;
	for(int s = 0; s < sessions.length(); s++) {
		JSONObject sessionObj = sessions.optJSONObject(s);
		if(sessionObj == null) continue;
		seq++;
		String sid = sessionObj.optString("sessionId", "");
		if(sessionId.equals(sid)) {
			targetSession = sessionObj;
			int no = sessionObj.optInt("sessionNo", 0);
			sessionNo = no > 0 ? no : seq;
			break;
		}
	}
	if(targetSession != null) break;
}

if(targetSession == null) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 차시를 찾지 못했습니다.");
	result.print();
	return;
}

String startDateTime = buildDateTime(targetSession.optString("startDate", ""), targetSession.optString("startTime", ""), true);
String endDateTime = buildDateTime(targetSession.optString("endDate", ""), targetSession.optString("endTime", ""), false);

java.util.ArrayList<Integer> videoIds = new java.util.ArrayList<Integer>();
java.util.ArrayList<Integer> examIds = new java.util.ArrayList<Integer>();
java.util.ArrayList<Integer> homeworkIds = new java.util.ArrayList<Integer>();

JSONArray contents = targetSession.optJSONArray("contents");
if(contents != null) {
	for(int c = 0; c < contents.length(); c++) {
		JSONObject content = contents.optJSONObject(c);
		if(content == null) continue;
		String type = content.optString("type", "");
		if("video".equalsIgnoreCase(type)) {
			int lid = content.optInt("lessonId", 0);
			if(lid > 0) videoIds.add(lid);
		} else if("exam".equalsIgnoreCase(type)) {
			int eid = content.optInt("examModuleId", 0);
			if(eid <= 0) {
				try { eid = Integer.parseInt(content.optString("examId", "0")); } catch(Exception ignore) {}
			}
			if(eid > 0) examIds.add(eid);
		} else if("assignment".equalsIgnoreCase(type)) {
			int hid = content.optInt("homeworkId", 0);
			if(hid > 0) homeworkIds.add(hid);
		}
	}
}

CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
ExamUserDao examUser = new ExamUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();

DataSet students = courseUser.query(
	" SELECT cu.id course_user_id, u.login_id, u.user_nm "
	+ " FROM " + courseUser.table + " cu "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id "
	+ " WHERE cu.course_id = " + courseId + " AND cu.site_id = " + siteId + " AND cu.status NOT IN (-1, -4) "
	+ " ORDER BY u.user_nm ASC, cu.id ASC "
);

java.util.ArrayList<Integer> studentIds = new java.util.ArrayList<Integer>();
students.first();
while(students.next()) studentIds.add(students.i("course_user_id"));

java.util.HashMap<String, String> videoCompleteMap = new java.util.HashMap<String, String>();
java.util.HashMap<String, String> examSubmitMap = new java.util.HashMap<String, String>();
java.util.HashMap<String, String> homeworkSubmitMap = new java.util.HashMap<String, String>();

String studentIn = studentIds.size() > 0 ? Malgn.join(",", studentIds.toArray()) : "0";
// 왜: Malgn.join이 Object 배열에서 예외가 날 수 있어 안전하게 숫자 리스트를 만든다.
studentIn = joinInts(studentIds);

if(videoIds.size() > 0) {
	String videoIn = Malgn.join(",", videoIds.toArray());
	videoIn = joinInts(videoIds);
	DataSet cp = courseProgress.query(
		" SELECT course_user_id, lesson_id, complete_yn, complete_date, last_date "
		+ " FROM " + courseProgress.table
		+ " WHERE status = 1 AND course_user_id IN (" + studentIn + ") AND lesson_id IN (" + videoIn + ")"
	);
	while(cp.next()) {
		String key = cp.i("course_user_id") + "_" + cp.i("lesson_id");
		String dt = safeDate(cp.s("complete_date"), cp.s("last_date"));
		if("Y".equals(cp.s("complete_yn"))) videoCompleteMap.put(key, dt);
	}
}

if(examIds.size() > 0) {
	String examIn = Malgn.join(",", examIds.toArray());
	examIn = joinInts(examIds);
	DataSet eu = examUser.query(
		" SELECT course_user_id, exam_id, submit_yn, submit_date, reg_date "
		+ " FROM " + examUser.table
		+ " WHERE status = 1 AND course_user_id IN (" + studentIn + ") AND exam_id IN (" + examIn + ")"
	);
	while(eu.next()) {
		String key = eu.i("course_user_id") + "_" + eu.i("exam_id");
		String dt = safeDate(eu.s("submit_date"), eu.s("reg_date"));
		if("Y".equals(eu.s("submit_yn"))) examSubmitMap.put(key, dt);
	}
}

if(homeworkIds.size() > 0) {
	String homeworkIn = Malgn.join(",", homeworkIds.toArray());
	homeworkIn = joinInts(homeworkIds);
	DataSet hu = homeworkUser.query(
		" SELECT course_user_id, homework_id, submit_yn, mod_date, reg_date "
		+ " FROM " + homeworkUser.table
		+ " WHERE status = 1 AND course_user_id IN (" + studentIn + ") AND homework_id IN (" + homeworkIn + ")"
	);
	while(hu.next()) {
		String key = hu.i("course_user_id") + "_" + hu.i("homework_id");
		String dt = safeDate(hu.s("mod_date"), hu.s("reg_date"));
		if("Y".equals(hu.s("submit_yn"))) homeworkSubmitMap.put(key, dt);
	}
}

DataSet data = new DataSet();
students.first();
while(students.next()) {
	int cuid = students.i("course_user_id");
	int videoDone = 0;
	int examDone = 0;
	int homeworkDone = 0;

	for(Integer lid : videoIds) {
		String key = cuid + "_" + lid;
		String dt = videoCompleteMap.get(key);
		if(dt != null && isWithinPeriod(dt, startDateTime, endDateTime)) videoDone++;
	}
	for(Integer eid : examIds) {
		String key = cuid + "_" + eid;
		String dt = examSubmitMap.get(key);
		if(dt != null && isWithinPeriod(dt, startDateTime, endDateTime)) examDone++;
	}
	for(Integer hid : homeworkIds) {
		String key = cuid + "_" + hid;
		String dt = homeworkSubmitMap.get(key);
		if(dt != null && isWithinPeriod(dt, startDateTime, endDateTime)) homeworkDone++;
	}

	int videoTotal = videoIds.size();
	int examTotal = examIds.size();
	int homeworkTotal = homeworkIds.size();
	int totalCount = videoTotal + examTotal + homeworkTotal;
	int doneCount = videoDone + examDone + homeworkDone;
	String attendYn = (totalCount > 0 && doneCount == totalCount) ? "Y" : "N";

	data.addRow();
	data.put("course_user_id", cuid);
	data.put("student_id", students.s("login_id"));
	data.put("name", students.s("user_nm"));
	data.put("attend_yn", attendYn);
	data.put("video_done_cnt", videoDone);
	data.put("video_total_cnt", videoTotal);
	data.put("exam_done_cnt", examDone);
	data.put("exam_total_cnt", examTotal);
	data.put("homework_done_cnt", homeworkDone);
	data.put("homework_total_cnt", homeworkTotal);
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", data);
result.print();

%>
