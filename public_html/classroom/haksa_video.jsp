<%@ page pageEncoding="utf-8" %><%@ page import="org.json.*" %><%@ include file="init.jsp" %><%!
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
%><%

//왜 필요한가:
//- 학사 동영상은 프리뷰로 열리면 진도/출석이 저장되지 않습니다.
//- 그래서 기간 체크 후, viewer.jsp로 넘겨 진도 저장이 되도록 게이트를 둡니다.

int lessonId = m.ri("lesson_id");
String sessionId = m.rs("session_id");
// 왜: classroom/init.jsp에서도 haksaCuid 변수를 쓰기 때문에, 여기서는 다른 이름을 사용합니다.
String haksaCuidParam = m.rs("haksa_cuid");

if(lessonId <= 0 || "".equals(sessionId)) {
	m.jsErrClose("동영상 정보가 없습니다.");
	return;
}

// 학사 키 보정
String hkCourseCode = cuinfo.s("haksa_course_code");
String hkOpenYear = cuinfo.s("haksa_open_year");
String hkOpenTerm = cuinfo.s("haksa_open_term");
String hkBunbanCode = cuinfo.s("haksa_bunban_code");
String hkGroupCode = cuinfo.s("haksa_group_code");

if("".equals(hkCourseCode) || "".equals(hkOpenYear) || "".equals(hkOpenTerm) || "".equals(hkBunbanCode) || "".equals(hkGroupCode)) {
	if(!"".equals(haksaCuidParam)) {
		String[] parts = haksaCuidParam.split("_");
		if(parts.length >= 5) {
			hkCourseCode = parts[0];
			hkOpenYear = parts[1];
			hkOpenTerm = parts[2];
			hkBunbanCode = parts[3];
			hkGroupCode = parts[4];
		}
	}
}

if("".equals(hkCourseCode) || "".equals(hkOpenYear) || "".equals(hkOpenTerm) || "".equals(hkBunbanCode) || "".equals(hkGroupCode)) {
	m.jsErrClose("학사 과목 키가 없어 동영상을 열 수 없습니다.");
	return;
}

PolyCourseSettingDao setting = new PolyCourseSettingDao();
DataSet info = setting.find(
	"site_id = " + siteId
	+ " AND course_code = ? AND open_year = ? AND open_term = ? AND bunban_code = ? AND group_code = ?"
	+ " AND status != -1"
	, new Object[] { hkCourseCode, hkOpenYear, hkOpenTerm, hkBunbanCode, hkGroupCode }
);

if(!info.next()) {
	m.jsErrClose("강의목차를 찾지 못했습니다.");
	return;
}

String curriculumJson = info.s("curriculum_json");
if("".equals(curriculumJson)) {
	m.jsErrClose("강의목차가 비어 있습니다.");
	return;
}

JSONArray weeks = new JSONArray(curriculumJson);
JSONObject targetSession = null;
int sessionNo = 0;
int seq = 0;
boolean lessonMatched = false;
int curriculumCompleteTimeMin = 0; // 학사 목차(커리큘럼)에서 설정한 인정시간(분)

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
			JSONArray contents = sessionObj.optJSONArray("contents");
			if(contents != null) {
				for(int c = 0; c < contents.length(); c++) {
					JSONObject content = contents.optJSONObject(c);
					if(content == null) continue;
					String type = content.optString("type", "");
					if(!"video".equalsIgnoreCase(type)) continue;
					if(lessonId == content.optInt("lessonId", 0)) {
						lessonMatched = true;
						// 왜: 교수자 화면에서 설정한 인정시간(completeTime)이 DB(LM_LESSON.complete_time)와 어긋나면
						//     진도율/완료 판정이 잘못될 수 있어, 재생 전에 여기서 보정합니다.
						curriculumCompleteTimeMin = content.optInt("completeTime", 0);
						if(curriculumCompleteTimeMin <= 0) curriculumCompleteTimeMin = content.optInt("complete_time", 0);
						break;
					}
				}
			}
			break;
		}
	}
	if(targetSession != null) break;
}

if(targetSession == null) {
	m.jsErrClose("차시 정보를 찾지 못했습니다.");
	return;
}
if(!lessonMatched) {
	m.jsErrClose("해당 차시에 등록된 영상이 아닙니다.");
	return;
}

String startDateTime = buildDateTime(targetSession.optString("startDate", ""), targetSession.optString("startTime", ""), true);
String endDateTime = buildDateTime(targetSession.optString("endDate", ""), targetSession.optString("endTime", ""), false);
// 왜: classroom/init.jsp에서도 now 변수를 쓰기 때문에, 여기서는 다른 이름을 사용합니다.
String nowDt = m.time("yyyyMMddHHmmss");

if(!"".equals(startDateTime) && !"".equals(endDateTime)) {
	if(nowDt.compareTo(startDateTime) < 0 || nowDt.compareTo(endDateTime) > 0) {
		m.jsErrClose("차시 수강기간이 아닙니다.");
		return;
	}
}

// 왜: classroom/init.jsp에서 cuid(수강자ID)가 이미 확정되어 있으므로 재정의하지 않습니다.
int mappedCourseId = cuinfo.i("course_id");

if(mappedCourseId <= 0 || cuid <= 0) {
	m.jsErrClose("과정 정보가 없어 동영상을 열 수 없습니다.");
	return;
}

LessonDao lesson = new LessonDao();
DataSet lessonInfo = lesson.find("id = " + lessonId + " AND site_id = " + siteId + " AND status = 1", "id, total_time, complete_time");
if(!lessonInfo.next()) {
	m.jsErrClose("레슨 정보를 찾지 못했습니다.");
	return;
}

// 인정시간 보정(학사 커리큘럼 값 우선)
if(curriculumCompleteTimeMin > 0 && lessonInfo.i("complete_time") != curriculumCompleteTimeMin) {
	lesson.clear();
	lesson.item("complete_time", curriculumCompleteTimeMin);
	// 왜: 총 시간이 비어 있는 영상은 인정시간을 기본값으로 써서 진도율 계산이 0/100으로 튀지 않게 합니다.
	if(lessonInfo.i("total_time") <= 0) lesson.item("total_time", curriculumCompleteTimeMin);
	lesson.update("id = " + lessonId + " AND site_id = " + siteId + " AND status = 1");
}

CourseLessonDao courseLesson = new CourseLessonDao();
int exist = courseLesson.findCount("course_id = " + mappedCourseId + " AND lesson_id = " + lessonId + " AND chapter = " + sessionNo);

String sDate = onlyDigits(targetSession.optString("startDate", ""));
String eDate = onlyDigits(targetSession.optString("endDate", ""));
String sTime = onlyDigits(targetSession.optString("startTime", ""));
String eTime = onlyDigits(targetSession.optString("endTime", ""));
if(sDate.length() >= 8) sDate = sDate.substring(0, 8);
if(eDate.length() >= 8) eDate = eDate.substring(0, 8);
if(sTime.length() >= 4) sTime = sTime.substring(0, 4) + "00";
if(eTime.length() >= 4) eTime = eTime.substring(0, 4) + "59";

if(exist > 0) {
	courseLesson.item("start_date", sDate);
	courseLesson.item("end_date", eDate);
	courseLesson.item("start_time", sTime);
	courseLesson.item("end_time", eTime);
	courseLesson.update("course_id = " + mappedCourseId + " AND lesson_id = " + lessonId + " AND chapter = " + sessionNo);
} else {
	courseLesson.item("course_id", mappedCourseId);
	courseLesson.item("lesson_id", lessonId);
	courseLesson.item("section_id", 0);
	courseLesson.item("site_id", siteId);
	courseLesson.item("chapter", sessionNo);
	courseLesson.item("start_day", 0);
	courseLesson.item("period", 0);
	courseLesson.item("start_date", sDate);
	courseLesson.item("end_date", eDate);
	courseLesson.item("start_time", sTime);
	courseLesson.item("end_time", eTime);
	courseLesson.item("lesson_hour", 1.00);
	courseLesson.item("progress_yn", "Y");
	courseLesson.item("status", 1);
	if(!courseLesson.insert()) {
		m.jsErrClose("차시 등록 중 오류가 발생했습니다.");
		return;
	}
}

String qs = "cuid=" + cuid + "&lid=" + lessonId + "&chapter=" + sessionNo;
if(!"".equals(haksaCuidParam)) qs += "&haksa_cuid=" + haksaCuidParam;

m.redirect("../classroom/viewer.jsp?" + qs);
%>
