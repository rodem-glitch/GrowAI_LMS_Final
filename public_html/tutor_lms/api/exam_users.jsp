<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 시험 > 제출현황/채점 화면에서, 학생별 제출/점수 정보를 DB에서 가져와야 합니다.

int courseId = m.ri("course_id");
int examId = m.ri("exam_id");
if(0 == courseId || 0 == examId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, exam_id가 필요합니다.");
	result.print();
	return;
}

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 시험 제출현황을 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet minfo = courseModule.query(
	" SELECT a.assign_score, a.start_date, a.end_date, a.retry_yn, a.retry_cnt, a.result_yn "
	+ " , e.exam_nm, e.exam_time, e.onoff_type "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.site_id = " + siteId + " AND e.status != -1 "
	+ " WHERE a.course_id = " + courseId + " AND a.module = 'exam' AND a.module_id = " + examId + " AND a.status = 1 "
);
if(!minfo.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 시험이 과목에 배치되어 있지 않습니다.");
	result.print();
	return;
}

DataSet list = courseUser.query(
	" SELECT cu.id course_user_id, cu.user_id "
	+ " , u.login_id, u.user_nm "
	+ " , eu.submit_yn, eu.submit_date, eu.confirm_yn, eu.confirm_date, eu.marking_score, eu.score "
	+ " FROM " + courseUser.table + " cu "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id AND u.status != -1 "
	+ " LEFT JOIN " + examUser.table + " eu ON eu.course_user_id = cu.id AND eu.exam_id = " + examId + " AND eu.exam_step = 1 AND eu.status = 1 "
	+ " WHERE cu.site_id = " + siteId + " AND cu.course_id = " + courseId + " AND cu.status IN (1,3) "
	+ " ORDER BY u.user_nm ASC, cu.id ASC "
);

while(list.next()) {
	boolean submitted = "Y".equals(list.s("submit_yn"));
	list.put("submitted", submitted);
	list.put("submitted_at", submitted && !"".equals(list.s("submit_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("submit_date")) : "-");
	list.put("confirm", "Y".equals(list.s("confirm_yn")));
	list.put("confirm_at", !"".equals(list.s("confirm_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("confirm_date")) : "-");

	double marking = list.d("marking_score");
	double convScore = Math.min(minfo.d("assign_score"), minfo.d("assign_score") * marking / 100.0);
	list.put("marking_score_conv", m.nf(marking, 0));
	list.put("score_conv", m.nf(convScore, 2));
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", list);
result.put("rst_exam", minfo);
result.print();

%>

