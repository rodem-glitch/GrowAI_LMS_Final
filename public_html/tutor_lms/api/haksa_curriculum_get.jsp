<%@ page pageEncoding="utf-8" %><%@ page import="org.json.*" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 학사 과목 강의목차(주차/차시/콘텐츠)를 DB에서 읽어옵니다.
//- 그런데 운영 중에는 "학생 화면(강의평가/시험/과제)은 보이는데, 교수자 화면(강의목차/시험/과제)은 비어 보이는" 케이스가 생길 수 있습니다.
//  - 원인: 실제 시험/과제는 LM_COURSE_MODULE에 있는데, 학사 목차 JSON(LM_POLY_COURSE_SETTING.curriculum_json)이 비어 있는 경우가 있습니다.
//- 그래서 DB 목차가 비어 있으면, 매핑된 LMS 과정의 모듈(시험/과제)을 기반으로 목차 JSON을 자동 생성해 저장/반환합니다.

String courseCode = m.rs("course_code");
String openYear = m.rs("open_year");
String openTerm = m.rs("open_term");
String bunbanCode = m.rs("bunban_code");
String groupCode = m.rs("group_code");

if("".equals(courseCode) || "".equals(openYear) || "".equals(openTerm) || "".equals(bunbanCode) || "".equals(groupCode)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "학사 과목 키(course_code/open_year/open_term/bunban_code/group_code)가 필요합니다.");
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

DataSet data = new DataSet();
data.addRow();

String curriculumJson = "";
if(info.next()) curriculumJson = info.s("curriculum_json");

boolean needSave = false;
JSONArray normalizedWeeks = null;

// 1) 기존 데이터가 v1(콘텐츠 배열) 형태이면 v2(주차→차시→콘텐츠)로 변환해서 저장합니다.
if(!"".equals(curriculumJson)) {
	try {
		JSONArray rawArr = new JSONArray(curriculumJson);
		JSONObject first = rawArr.length() > 0 ? rawArr.optJSONObject(0) : null;
		boolean isV2 = first != null && first.has("sessions");
		boolean isV1 = !isV2 && first != null && first.has("type");

		if(isV2) {
			normalizedWeeks = rawArr;
		} else if(isV1) {
			java.util.HashMap<Integer, JSONArray> weekContents = new java.util.HashMap<Integer, JSONArray>();
			int maxWeek = 1;
			for(int i = 0; i < rawArr.length(); i++) {
				JSONObject c = rawArr.optJSONObject(i);
				if(c == null) continue;
				int w = c.optInt("weekNumber", 1);
				if(w <= 0) w = 1;
				if(w > maxWeek) maxWeek = w;
				JSONArray list = weekContents.get(w);
				if(list == null) { list = new JSONArray(); weekContents.put(w, list); }
				list.put(c);
			}
			JSONArray weeks = new JSONArray();
			for(int w = 1; w <= maxWeek; w++) {
				JSONArray list = weekContents.get(w);
				if(list == null) list = new JSONArray();
				JSONObject sessionObj = new JSONObject();
				sessionObj.put("sessionId", "session_migrated_" + w);
				sessionObj.put("sessionName", "1차시");
				sessionObj.put("isExpanded", w == 1);
				sessionObj.put("contents", list);

				JSONObject weekObj = new JSONObject();
				weekObj.put("weekNumber", w);
				weekObj.put("title", w + "주차");
				weekObj.put("isExpanded", w == 1);
				weekObj.put("sessions", new JSONArray().put(sessionObj));
				weeks.put(weekObj);
			}
			normalizedWeeks = weeks;
			needSave = true;
		}
	} catch(Exception ignore) {
		// 왜: JSON이 깨진 경우에는 그대로 두면 화면이 계속 깨집니다.
		//     아래의 "모듈 기반 자동 복구"로 살릴 수 있으면 살리고, 아니면 빈값으로 처리합니다.
		curriculumJson = "";
		normalizedWeeks = null;
	}
}

// 2) DB 목차가 비어 있으면, LM_COURSE_MODULE(시험/과제)에서 목차를 자동 생성합니다.
if(("".equals(curriculumJson) || normalizedWeeks == null) ) {
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

		int mappedCourseId = 0;
		String studySdate = "";
		if(mappedCourse.next()) {
			mappedCourseId = mappedCourse.i("id");
			studySdate = mappedCourse.s("study_sdate");
		}

		if(mappedCourseId > 0) {
			CourseModuleDao courseModule = new CourseModuleDao();
			DataSet modules = courseModule.find(
				"course_id = " + mappedCourseId
				+ " AND status = 1"
				+ " AND module IN ('exam','homework')"
				, "*"
				, "start_date ASC, module ASC"
			);

			if(modules.size() > 0) {
				java.util.HashMap<Integer, JSONArray> weekContents = new java.util.HashMap<Integer, JSONArray>();
				int maxWeek = 1;
				while(modules.next()) {
					String mod = modules.s("module");
					int moduleId = modules.i("module_id");
					String title = modules.s("module_nm");

					int weekNumber = 1;
					try {
						String startDate = modules.s("start_date");
						String startYmd = startDate != null && startDate.length() >= 8 ? startDate.substring(0, 8) : "";
						if(!"".equals(studySdate) && !"".equals(startYmd)) {
							int diff = m.diffDate("D", studySdate, startYmd);
							if(diff >= 0) weekNumber = (diff / 7) + 1;
						}
					} catch(Exception ignore2) {}
					if(weekNumber <= 0) weekNumber = 1;
					if(weekNumber > maxWeek) maxWeek = weekNumber;

					JSONObject content = new JSONObject();
					content.put("id", mod + "_" + moduleId);
					content.put("weekNumber", weekNumber);
					content.put("type", "exam".equals(mod) ? "exam" : "assignment");
					content.put("title", !"".equals(title) ? title : ("exam".equals(mod) ? "시험" : "과제"));
					content.put("createdAt", m.time("yyyy-MM-dd'T'HH:mm:ss"));

					if("exam".equals(mod)) {
						content.put("examId", String.valueOf(moduleId));
						content.put("examModuleId", moduleId);
						JSONObject examSettings = new JSONObject();
						examSettings.put("testPeriod", 1);
						examSettings.put("points", modules.i("assign_score"));
						examSettings.put("allowRetake", "Y".equalsIgnoreCase(modules.s("retry_yn")));
						examSettings.put("retakeScore", modules.i("retry_score"));
						examSettings.put("retakeCount", modules.i("retry_cnt"));
						examSettings.put("showResults", !"N".equalsIgnoreCase(modules.s("result_yn")));
						content.put("examSettings", examSettings);
					} else {
						content.put("homeworkId", moduleId);
					}

					JSONArray list = weekContents.get(weekNumber);
					if(list == null) { list = new JSONArray(); weekContents.put(weekNumber, list); }
					list.put(content);
				}

				JSONArray weeks = new JSONArray();
				for(int w = 1; w <= maxWeek; w++) {
					JSONArray list = weekContents.get(w);
					if(list == null) list = new JSONArray();

					JSONObject sessionObj = new JSONObject();
					sessionObj.put("sessionId", "session_imported_" + w);
					sessionObj.put("sessionName", "1차시");
					sessionObj.put("isExpanded", w == 1);
					sessionObj.put("contents", list);

					JSONObject weekObj = new JSONObject();
					weekObj.put("weekNumber", w);
					weekObj.put("title", w + "주차");
					weekObj.put("isExpanded", w == 1);
					weekObj.put("sessions", new JSONArray().put(sessionObj));
					weeks.put(weekObj);
				}

				normalizedWeeks = weeks;
				needSave = true;
			}
		}
	} catch(Exception ignore) {}
}

// 2-1) 학사 목차의 동영상 인정시간(completeTime) → LM_LESSON.complete_time 동기화
// 왜 필요한가:
// - 교수자 화면은 학사 목차 JSON에 인정시간을 저장하지만,
//   진도율/완료 판정(CourseProgressDao)은 LM_LESSON.complete_time을 기준으로 계산합니다.
// - 두 값이 어긋나면 "22초 봤는데 100%" 같은 문제가 생길 수 있어, 조회 시점에 최소한으로 보정합니다.
try {
	int mappedCourseIdForSync = 0;
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
		if(mappedCourse.next()) mappedCourseIdForSync = mappedCourse.i("id");
	} catch(Exception ignore2) {}

	if(normalizedWeeks != null && normalizedWeeks.length() > 0) {
		LessonDao lesson = new LessonDao();
		CourseProgressDao courseProgress = new CourseProgressDao(siteId);
		String now = m.time("yyyyMMddHHmmss");

		java.util.HashSet<Integer> changedLessonIds = new java.util.HashSet<Integer>();

		int seq = 0;
		for(int i = 0; i < normalizedWeeks.length(); i++) {
			JSONObject w = normalizedWeeks.optJSONObject(i);
			if(w == null) continue;
			JSONArray sessions = w.optJSONArray("sessions");
			if(sessions == null) continue;
			for(int s = 0; s < sessions.length(); s++) {
				JSONObject sessionObj = sessions.optJSONObject(s);
				if(sessionObj == null) continue;
				seq++;
				JSONArray contents = sessionObj.optJSONArray("contents");
				if(contents == null) continue;
				for(int c = 0; c < contents.length(); c++) {
					JSONObject content = contents.optJSONObject(c);
					if(content == null) continue;
					String t = content.optString("type", "");
					if(!"video".equalsIgnoreCase(t)) continue;

					int lessonId = content.optInt("lessonId", 0);
					int completeTime = content.optInt("completeTime", 0);
					if(completeTime <= 0) completeTime = content.optInt("complete_time", 0);
					if(lessonId <= 0 || completeTime <= 0) continue;

					DataSet linfo = lesson.find("id = " + lessonId + " AND site_id = " + siteId + " AND status = 1", "total_time, complete_time");
					if(!linfo.next()) continue;
					if(linfo.i("complete_time") == completeTime) continue;

					lesson.clear();
					lesson.item("complete_time", completeTime);
					if(linfo.i("total_time") <= 0) lesson.item("total_time", completeTime);
					lesson.update("id = " + lessonId + " AND site_id = " + siteId + " AND status = 1");
					changedLessonIds.add(Integer.valueOf(lessonId));
				}
			}
		}

		// 왜: 인정시간이 바뀌면 과거 진도율/완료여부도 함께 보정해야 교수자 "진도/출석" 화면이 맞습니다.
		if(mappedCourseIdForSync > 0 && changedLessonIds.size() > 0) {
			for(Integer lidObj : changedLessonIds) {
				int lessonId = lidObj.intValue();
				DataSet linfo = lesson.find("id = " + lessonId + " AND site_id = " + siteId + " AND status = 1", "total_time, complete_time");
				if(!linfo.next()) continue;
				int totalSec = linfo.i("total_time") * 60;
				int completeSec = linfo.i("complete_time") * 60;

				String ratioExpr =
					(completeSec <= 0)
					? "100.0"
					: ("(CASE"
						+ " WHEN " + totalSec + " > 0 AND LEAST(IFNULL(cp.study_time,0), IFNULL(cp.last_time,0)) < " + completeSec + " THEN LEAST(100.0, (LEAST(IFNULL(cp.study_time,0), IFNULL(cp.last_time,0)) / " + (double)totalSec + ") * 100.0)"
						+ " ELSE 100.0 END)");

				String completeExpr =
					(completeSec <= 0)
					? "'Y'"
					: ("(CASE"
						+ " WHEN LEAST(IFNULL(cp.study_time,0), IFNULL(cp.last_time,0)) >= " + completeSec + " THEN 'Y'"
						+ " WHEN " + totalSec + " > 0 AND LEAST(IFNULL(cp.study_time,0), IFNULL(cp.last_time,0)) >= " + totalSec + " THEN 'Y'"
						+ " ELSE 'N' END)");

				courseProgress.execute(
					"UPDATE " + courseProgress.table + " cp "
					+ " INNER JOIN LM_COURSE_USER cu ON cu.id = cp.course_user_id AND cu.course_id = " + mappedCourseIdForSync + " AND cu.site_id = " + siteId + " AND cu.status NOT IN (-1, -4) "
					+ " SET cp.ratio = " + ratioExpr + ", cp.complete_yn = " + completeExpr
					+ " , cp.complete_date = (CASE WHEN " + completeExpr + " = 'Y' THEN (CASE WHEN IFNULL(cp.complete_date,'') = '' THEN '" + now + "' ELSE cp.complete_date END) ELSE '' END) "
					+ " WHERE cp.site_id = " + siteId + " AND cp.status = 1 AND cp.lesson_id = " + lessonId
				);
			}
		}
	}
} catch(Exception ignore) {}

// 3) 필요 시 DB에 저장(학생/교수자 화면 동일 데이터 보장)
if(needSave && normalizedWeeks != null) {
	try {
		String normalizedJson = normalizedWeeks.toString();
		setting.PK = "site_id,course_code,open_year,open_term,bunban_code,group_code";
		setting.useSeq = "N";

		int count = setting.findCount(
			"site_id = " + siteId
			+ " AND course_code = ? AND open_year = ? AND open_term = ? AND bunban_code = ? AND group_code = ?"
			+ " AND status != -1"
			, new Object[] { courseCode, openYear, openTerm, bunbanCode, groupCode }
		);

		setting.item("curriculum_json", normalizedJson);
		setting.item("mod_date", m.time("yyyyMMddHHmmss"));

		if(count > 0) {
			String safeCourseCode = m.replace(courseCode, "'", "''");
			String safeOpenYear = m.replace(openYear, "'", "''");
			String safeOpenTerm = m.replace(openTerm, "'", "''");
			String safeBunbanCode = m.replace(bunbanCode, "'", "''");
			String safeGroupCode = m.replace(groupCode, "'", "''");

			setting.update(
				"site_id = " + siteId
				+ " AND course_code = '" + safeCourseCode + "'"
				+ " AND open_year = '" + safeOpenYear + "'"
				+ " AND open_term = '" + safeOpenTerm + "'"
				+ " AND bunban_code = '" + safeBunbanCode + "'"
				+ " AND group_code = '" + safeGroupCode + "'"
				+ " AND status != -1"
			);
		} else {
			setting.item("site_id", siteId);
			setting.item("course_code", courseCode);
			setting.item("open_year", openYear);
			setting.item("open_term", openTerm);
			setting.item("bunban_code", bunbanCode);
			setting.item("group_code", groupCode);
			setting.item("reg_date", m.time("yyyyMMddHHmmss"));
			setting.item("status", 1);
			setting.insert();
		}

		curriculumJson = normalizedJson;
	} catch(Exception ignore) {}
} else if(normalizedWeeks != null) {
	// 변환만 하고 저장하지 않는 경우(혹시라도 insert/update 실패 등)에도 화면은 최대한 보여줍니다.
	curriculumJson = normalizedWeeks.toString();
}

data.put("curriculum_json", curriculumJson);

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", data);
result.print();

%>

