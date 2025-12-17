<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 특정 차시(레슨)를 선택했을 때, 수강생별로 진도율/학습시간/완료여부를 표로 보여줘야 합니다.
//- 그래서 LM_COURSE_USER(수강생) + TB_USER(회원) + LM_COURSE_PROGRESS(진도)를 합쳐 목록을 내려줍니다.

int courseId = m.ri("course_id");
int lessonId = m.ri("lesson_id");
if(0 == courseId || 0 == lessonId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id와 lesson_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseUserDao courseUser = new CourseUserDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
UserDao user = new UserDao();

//권한: 교수자는 본인 과목(주강사)만, 관리자는 전체
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 진도를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet list = courseUser.query(
	" SELECT cu.id course_user_id, cu.user_id, cu.course_id "
	+ " , u.login_id, u.user_nm, u.email "
	+ " , IFNULL(cp.ratio, 0) ratio, IFNULL(cp.study_time, 0) study_time, IFNULL(cp.view_cnt, 0) view_cnt "
	+ " , IFNULL(cp.complete_yn, 'N') complete_yn, IFNULL(cp.complete_date, '') complete_date, IFNULL(cp.last_date, '') last_date "
	+ " FROM " + courseUser.table + " cu "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id "
	+ " LEFT JOIN " + courseProgress.table + " cp ON cp.course_user_id = cu.id AND cp.lesson_id = " + lessonId + " AND cp.site_id = " + siteId + " AND cp.status = 1 "
	+ " WHERE cu.site_id = " + siteId + " AND cu.course_id = " + courseId + " AND cu.status NOT IN (-1, -4) "
	+ " ORDER BY u.user_nm ASC, cu.id ASC "
);

while(list.next()) {
	list.put("student_id", list.s("login_id"));
	list.put("name", list.s("user_nm"));
	list.put("email", list.s("email"));
	list.put("ratio", Malgn.round(list.d("ratio"), 1));

	int time = list.i("study_time");
	list.put("study_time_conv", String.format("%02d:%02d:%02d", (time / 3600), (time % 3600 / 60), (time % 3600 % 60)));

	String completeDate = list.s("complete_date");
	list.put("complete_date_conv", !"".equals(completeDate) ? m.time("yyyy.MM.dd HH:mm", completeDate) : "-");

	String lastDate = list.s("last_date");
	list.put("last_date_conv", !"".equals(lastDate) ? m.time("yyyy.MM.dd HH:mm", lastDate) : "-");
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

