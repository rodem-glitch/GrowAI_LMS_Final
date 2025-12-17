<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 운영 중 평가 비율/수료 기준이 바뀔 수 있으므로 수정 API가 필요합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
	result.print();
	return;
}

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();

if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 평가설정을 수정할 권한이 없습니다.");
		result.print();
		return;
	}
}

//배점(0~100 범위 권장)
f.addElement("assign_progress", 100, "hname:'출석 배점', option:'number'");
f.addElement("assign_exam", 0, "hname:'시험 배점', option:'number'");
f.addElement("assign_homework", 0, "hname:'과제 배점', option:'number'");
f.addElement("assign_forum", 0, "hname:'토론 배점', option:'number'");
f.addElement("assign_etc", 0, "hname:'기타 배점', option:'number'");

//수료 기준
f.addElement("limit_progress", 60, "hname:'진도 기준', option:'number'");
f.addElement("limit_exam", 0, "hname:'시험 기준', option:'number'");
f.addElement("limit_homework", 0, "hname:'과제 기준', option:'number'");
f.addElement("limit_forum", 0, "hname:'토론 기준', option:'number'");
f.addElement("limit_etc", 0, "hname:'기타 기준', option:'number'");
f.addElement("limit_total_score", 60, "hname:'총점 기준', option:'number'");

//수료(완료) 기준
f.addElement("complete_limit_progress", 60, "hname:'수료 진도 기준', option:'number'");
f.addElement("complete_limit_total_score", 60, "hname:'수료 총점 기준', option:'number'");

//기타 옵션
f.addElement("assign_survey_yn", "N", "hname:'설문참여 포함'");
f.addElement("push_survey_yn", "N", "hname:'설문독려'");
f.addElement("pass_yn", "N", "hname:'합격 상태 사용'");

course.item("assign_progress", f.getInt("assign_progress"));
course.item("assign_exam", f.getInt("assign_exam"));
course.item("assign_homework", f.getInt("assign_homework"));
course.item("assign_forum", f.getInt("assign_forum"));
course.item("assign_etc", f.getInt("assign_etc"));

course.item("limit_progress", f.getInt("limit_progress"));
course.item("limit_exam", f.getInt("limit_exam"));
course.item("limit_homework", f.getInt("limit_homework"));
course.item("limit_forum", f.getInt("limit_forum"));
course.item("limit_etc", f.getInt("limit_etc"));
course.item("limit_total_score", f.getInt("limit_total_score"));

course.item("complete_limit_progress", f.getInt("complete_limit_progress"));
course.item("complete_limit_total_score", f.getInt("complete_limit_total_score"));

course.item("assign_survey_yn", f.get("assign_survey_yn", "N"));
course.item("push_survey_yn", f.get("push_survey_yn", "N"));
course.item("pass_yn", f.get("pass_yn", "N"));
course.item("mod_date", m.time("yyyyMMddHHmmss"));

if(!course.update("id = " + courseId + " AND site_id = " + siteId + " AND status != -1")) {
	result.put("rst_code", "2000");
	result.put("rst_message", "저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", courseId);
result.print();

%>

