<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 진도 표에서 특정 수강생/차시를 눌렀을 때 "상세"(학습시간/마지막 위치/완료일 등)를 보여줄 수 있어야 합니다.
//- LM_COURSE_PROGRESS는 학습 플레이어가 저장하는 원본 데이터이므로, 그 값을 그대로 내려줍니다.

int courseId = m.ri("course_id");
int courseUserId = m.ri("course_user_id");
int lessonId = m.ri("lesson_id");
if(0 == courseId || 0 == courseUserId || 0 == lessonId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, course_user_id, lesson_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
LessonDao lesson = new LessonDao();
UserDao user = new UserDao();

//권한: 교수자는 본인 과목(주/보조강사)만, 관리자는 전체
if(!isAdmin) {
	// 왜: 보조강사도 진도/출석을 확인해야 하므로 major+minor를 모두 허용합니다.
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type IN ('major','minor') AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 진도를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet info = courseUser.query(
	" SELECT cu.id course_user_id, cu.user_id, cu.course_id "
	+ " , u.login_id, u.user_nm, u.email "
	+ " , cl.chapter "
	+ " , l.id lesson_id, l.lesson_nm, l.lesson_type, l.total_time, l.complete_time "
	+ " , IFNULL(cp.ratio, 0) ratio, IFNULL(cp.study_time, 0) study_time, IFNULL(cp.curr_time, 0) curr_time, IFNULL(cp.last_time, 0) last_time "
	+ " , IFNULL(cp.view_cnt, 0) view_cnt, IFNULL(cp.curr_page, '') curr_page, IFNULL(cp.study_page, 0) study_page "
	+ " , IFNULL(cp.complete_yn, 'N') complete_yn, IFNULL(cp.complete_date, '') complete_date, IFNULL(cp.last_date, '') last_date "
	+ " FROM " + courseUser.table + " cu "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id "
	+ " INNER JOIN " + courseLesson.table + " cl ON cl.course_id = cu.course_id AND cl.lesson_id = " + lessonId + " AND cl.site_id = " + siteId + " AND cl.status = 1 "
	+ " INNER JOIN " + lesson.table + " l ON l.id = cl.lesson_id AND l.status = 1 "
	+ " LEFT JOIN " + courseProgress.table + " cp ON cp.course_user_id = cu.id AND cp.lesson_id = cl.lesson_id AND cp.site_id = " + siteId + " AND cp.status = 1 "
	+ " WHERE cu.id = " + courseUserId + " AND cu.course_id = " + courseId + " AND cu.site_id = " + siteId + " AND cu.status NOT IN (-1, -4) "
);

if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 진도 정보가 없거나 조회 권한이 없습니다.");
	result.print();
	return;
}

info.put("student_id", info.s("login_id"));
info.put("name", info.s("user_nm"));
info.put("email", info.s("email"));
info.put("ratio", Malgn.round(info.d("ratio"), 1));

int time = info.i("study_time");
info.put("study_time_conv", String.format("%02d:%02d:%02d", (time / 3600), (time % 3600 / 60), (time % 3600 % 60)));

String completeDate = info.s("complete_date");
info.put("complete_date_conv", !"".equals(completeDate) ? m.time("yyyy.MM.dd HH:mm", completeDate) : "-");

String lastDate = info.s("last_date");
info.put("last_date_conv", !"".equals(lastDate) ? m.time("yyyy.MM.dd HH:mm", lastDate) : "-");

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", info);
result.print();

%>
