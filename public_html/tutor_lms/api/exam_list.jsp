<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 시험 탭에서, 과목에 배치된 시험 목록과 제출/채점 현황을 "운영 DB" 기준으로 보여주기 위함입니다.

int courseId = m.ri("course_id");
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
	result.print();
	return;
}

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();

//왜: 교수자는 본인 과목만, 관리자는 전체 과목을 조회할 수 있어야 합니다.
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 시험 정보를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + " AND status != -1");
if(!cinfo.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과목이 없습니다.");
	result.print();
	return;
}

DataSet list = courseModule.query(
	" SELECT a.module_id exam_id, a.module_nm, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score, a.result_yn, a.retry_yn, a.retry_cnt "
	+ " , e.exam_nm, e.exam_time, e.question_cnt, e.onoff_type "
	+ " , (SELECT COUNT(*) FROM " + courseUser.table + " cu "
		+ " WHERE cu.site_id = " + siteId + " AND cu.course_id = a.course_id AND cu.status IN (1,3)) total_cnt "
	+ " , (SELECT COUNT(*) FROM " + examUser.table + " eu "
		+ " INNER JOIN " + courseUser.table + " cu ON cu.id = eu.course_user_id AND cu.status IN (1,3) "
		+ " WHERE eu.exam_id = a.module_id AND eu.course_id = a.course_id "
		+ " AND eu.exam_step = 1 AND eu.status = 1 AND eu.submit_yn = 'Y') submitted_cnt "
	+ " , (SELECT COUNT(*) FROM " + examUser.table + " eu "
		+ " INNER JOIN " + courseUser.table + " cu ON cu.id = eu.course_user_id AND cu.status IN (1,3) "
		+ " WHERE eu.exam_id = a.module_id AND eu.course_id = a.course_id "
		+ " AND eu.exam_step = 1 AND eu.status = 1 AND eu.submit_yn = 'Y' AND eu.confirm_yn = 'Y') confirmed_cnt "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.site_id = " + siteId + " AND e.status != -1 "
	+ " WHERE a.course_id = " + courseId + " AND a.module = 'exam' AND a.status = 1 "
	+ " ORDER BY a.start_date ASC, a.end_date ASC, a.period ASC, a.chapter ASC, a.module_id ASC "
);

while(list.next()) {
	list.put("start_date_conv", !"".equals(list.s("start_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("start_date")) : "");
	list.put("end_date_conv", !"".equals(list.s("end_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("end_date")) : "");

	list.put("total_cnt", list.i("total_cnt"));
	list.put("submitted_cnt", list.i("submitted_cnt"));
	list.put("confirmed_cnt", list.i("confirmed_cnt"));
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

