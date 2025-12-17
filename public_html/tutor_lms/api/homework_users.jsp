<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 과제 > 제출현황/피드백 화면에서, 학생별 제출/점수/피드백 정보를 DB에서 가져와야 합니다.

int courseId = m.ri("course_id");
int homeworkId = m.ri("homework_id");
if(0 == courseId || 0 == homeworkId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, homework_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();
HomeworkDao homework = new HomeworkDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 과제 제출현황을 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet minfo = courseModule.query(
	" SELECT a.assign_score, a.start_date, a.end_date "
	+ " , h.homework_nm, h.onoff_type "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id AND h.site_id = " + siteId + " AND h.status != -1 "
	+ " WHERE a.course_id = " + courseId + " AND a.module = 'homework' AND a.module_id = " + homeworkId + " AND a.status = 1 "
);
if(!minfo.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과제가 과목에 배치되어 있지 않습니다.");
	result.print();
	return;
}

DataSet list = courseUser.query(
	" SELECT cu.id course_user_id, cu.user_id "
	+ " , u.login_id, u.user_nm "
	+ " , hu.submit_yn, hu.reg_date submit_date, hu.confirm_yn, hu.confirm_date, hu.marking_score, hu.score, hu.subject, hu.feedback "
	+ " , (SELECT COUNT(*) FROM " + new HomeworkTaskDao().table + " ht "
		+ " WHERE ht.site_id = " + siteId + " AND ht.course_id = " + courseId
		+ " AND ht.homework_id = " + homeworkId + " AND ht.course_user_id = cu.id AND ht.status = 1) task_cnt "
	+ " FROM " + courseUser.table + " cu "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id AND u.status != -1 "
	+ " LEFT JOIN " + homeworkUser.table + " hu ON hu.course_user_id = cu.id AND hu.homework_id = " + homeworkId + " AND hu.status = 1 "
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
result.put("rst_homework", minfo);
result.print();

%>
