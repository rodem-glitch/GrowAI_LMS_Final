<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 성적관리 탭에서, 학생별 점수(진도/시험/과제/총점)를 운영 DB에서 읽어와야 합니다.

int courseId = m.ri("course_id");
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
UserDao user = new UserDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 성적을 조회할 권한이 없습니다.");
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

DataSet list = courseUser.query(
	" SELECT cu.id course_user_id, cu.user_id "
	+ " , u.login_id, u.user_nm "
	+ " , cu.progress_ratio, cu.progress_score "
	+ " , cu.exam_score, cu.homework_score, cu.forum_score, cu.etc_score "
	+ " , cu.total_score "
	+ " FROM " + courseUser.table + " cu "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id AND u.status != -1 "
	+ " WHERE cu.site_id = " + siteId + " AND cu.course_id = " + courseId + " AND cu.status IN (1,3) "
	+ " ORDER BY u.user_nm ASC, cu.id ASC "
);

while(list.next()) {
	list.put("progress_ratio_conv", m.nf(list.d("progress_ratio"), 1));
	list.put("total_score_conv", m.nf(list.d("total_score"), 2));

	//간단 상태 계산(왜: 화면에서 뱃지 표시를 위해 최소한의 라벨이 필요합니다)
	String status = "미달";
	boolean passYn = "Y".equals(cinfo.s("pass_yn"));
	boolean meetPass = passYn
		&& list.d("progress_ratio") >= cinfo.d("limit_progress")
		&& (0 == cinfo.i("limit_total_score") || list.d("total_score") >= cinfo.d("limit_total_score"));
	boolean meetComplete = list.d("progress_ratio") >= cinfo.d("complete_limit_progress")
		&& (0 == cinfo.i("complete_limit_total_score") || list.d("total_score") >= cinfo.d("complete_limit_total_score"));
	if(meetPass) status = "합격";
	else if(meetComplete) status = "수료";
	list.put("status_label", status);
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.put("rst_course", cinfo);
result.print();

%>

