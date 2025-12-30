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

