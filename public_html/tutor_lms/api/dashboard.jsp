<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- `project`(React) 대시보드 화면은 "진행 중 과목/미확인 과제/미답변 Q&A" 같은 요약 정보를 보여줘야 합니다.
//- 화면에서 여러 API를 N번 호출하면 느려지므로, 대시보드 전용으로 필요한 데이터를 한 번에 내려줍니다.

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseUserDao courseUser = new CourseUserDao();
HomeworkDao homework = new HomeworkDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
ClBoardDao board = new ClBoardDao(siteId);
ClPostDao post = new ClPostDao();
UserDao user = new UserDao();

String today = m.time("yyyyMMdd");

//왜: 교수자는 본인 과목만, 관리자는 전체를 볼 수 있어야 합니다.
String joinTutor = "";
if(!isAdmin) {
	joinTutor = " INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ";
}

//=========================
// 1) 통계(카드)
//=========================

int activeCourseCnt = course.getOneInt(
	" SELECT COUNT(*) "
	+ " FROM " + course.table + " c "
	+ joinTutor
	+ " WHERE c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ " AND c.study_sdate != '' AND c.study_edate != '' "
	+ " AND c.study_sdate <= '" + today + "' AND c.study_edate >= '" + today + "' "
);

int pendingHomeworkCnt = course.getOneInt(
	" SELECT COUNT(*) "
	+ " FROM " + homeworkUser.table + " hu "
	+ " INNER JOIN " + courseUser.table + " cu ON cu.id = hu.course_user_id AND cu.status IN (1,3) AND cu.site_id = " + siteId + " "
	+ " INNER JOIN " + course.table + " c ON c.id = hu.course_id AND c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ (!isAdmin ? (" INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ") : "")
	+ " WHERE hu.status = 1 AND hu.submit_yn = 'Y' AND (hu.confirm_yn IS NULL OR hu.confirm_yn != 'Y') "
);

int unansweredQnaCnt = post.getOneInt(
	" SELECT COUNT(*) "
	+ " FROM " + post.table + " p "
	+ " INNER JOIN " + board.table + " b ON b.id = p.board_id AND b.site_id = " + siteId + " AND b.status = 1 AND b.code = 'qna' "
	+ " INNER JOIN " + course.table + " c ON c.id = p.course_id AND c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ (!isAdmin ? (" INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ") : "")
	+ " WHERE p.site_id = " + siteId + " AND p.depth = 'A' AND p.display_yn = 'Y' AND p.status != -1 "
	+ " AND p.proc_status != 1 "
);

DataSet stats = new DataSet();
stats.addRow();
stats.put("active_course_cnt", activeCourseCnt);
stats.put("pending_homework_cnt", pendingHomeworkCnt);
stats.put("unanswered_qna_cnt", unansweredQnaCnt);
stats.put("today", today);
stats.next();

//=========================
// 2) 진행 중 과목(상위 5개)
//=========================

DataSet courses = course.query(
	" SELECT c.id, c.course_cd, c.course_nm, c.study_sdate, c.study_edate "
	+ " , CASE WHEN IFNULL(c.etc2, '') = 'HAKSA_MAPPED' THEN 'haksa' ELSE 'prism' END source_type "
	+ " , (SELECT COUNT(*) FROM " + courseUser.table + " cu WHERE cu.site_id = " + siteId + " AND cu.course_id = c.id AND cu.status IN (1,3)) student_cnt "
	+ " , (SELECT IFNULL(AVG(cu.progress_ratio), 0) FROM " + courseUser.table + " cu WHERE cu.site_id = " + siteId + " AND cu.course_id = c.id AND cu.status IN (1,3)) avg_progress_ratio "
	+ " , (SELECT COUNT(*) FROM " + homeworkUser.table + " hu "
		+ " INNER JOIN " + courseUser.table + " cu2 ON cu2.id = hu.course_user_id AND cu2.status IN (1,3) "
		+ " WHERE cu2.site_id = " + siteId + " AND hu.course_id = c.id "
		+ " AND hu.status = 1 AND hu.submit_yn = 'Y' AND (hu.confirm_yn IS NULL OR hu.confirm_yn != 'Y')) pending_homework_cnt "
	+ " , (SELECT COUNT(*) FROM " + post.table + " p "
		+ " INNER JOIN " + board.table + " b ON b.id = p.board_id AND b.site_id = " + siteId + " AND b.status = 1 AND b.code = 'qna' "
		+ " WHERE p.site_id = " + siteId + " AND p.course_id = c.id AND p.depth = 'A' AND p.display_yn = 'Y' AND p.status != -1 "
		+ " AND p.proc_status != 1) unanswered_qna_cnt "
	+ " FROM " + course.table + " c "
	+ joinTutor
	+ " WHERE c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ " AND c.study_sdate != '' AND c.study_edate != '' "
	+ " AND c.study_sdate <= '" + today + "' AND c.study_edate >= '" + today + "' "
	+ " ORDER BY c.study_edate ASC, c.id DESC "
	+ " LIMIT 0, 5 "
);

while(courses.next()) {
	String ss = courses.s("study_sdate");
	String se = courses.s("study_edate");
	String ssConv = !"".equals(ss) ? m.time("yyyy.MM.dd", ss) : "";
	String seConv = !"".equals(se) ? m.time("yyyy.MM.dd", se) : "";
	courses.put("period_conv", (!"".equals(ssConv) && !"".equals(seConv)) ? (ssConv + " - " + seConv) : "-");

	courses.put("course_id_conv", !"".equals(courses.s("course_cd")) ? courses.s("course_cd") : (courses.i("id") + ""));
	courses.put("avg_progress_ratio_conv", m.nf(courses.d("avg_progress_ratio"), 1));
}

//=========================
// 3) 최근 과제 제출(상위 5개)
//=========================

DataSet submissions = homeworkUser.query(
	" SELECT hu.course_id, hu.homework_id, hu.course_user_id, hu.reg_date submit_date, hu.confirm_yn "
	+ " , c.course_nm "
	+ " , CASE WHEN IFNULL(c.etc2, '') = 'HAKSA_MAPPED' THEN 'haksa' ELSE 'prism' END source_type "
	+ " , h.homework_nm "
	+ " , u.user_nm, u.login_id "
	+ " FROM " + homeworkUser.table + " hu "
	+ " INNER JOIN " + courseUser.table + " cu ON cu.id = hu.course_user_id AND cu.site_id = " + siteId + " AND cu.status IN (1,3) "
	+ " INNER JOIN " + user.table + " u ON u.id = cu.user_id AND u.status != -1 "
	+ " INNER JOIN " + course.table + " c ON c.id = hu.course_id AND c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ (!isAdmin ? (" INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ") : "")
	+ " INNER JOIN " + homework.table + " h ON h.id = hu.homework_id AND h.site_id = " + siteId + " AND h.status != -1 "
	+ " WHERE hu.status = 1 AND hu.submit_yn = 'Y' "
	+ " ORDER BY (CASE WHEN hu.confirm_yn = 'Y' THEN 1 ELSE 0 END) ASC, hu.reg_date DESC "
	+ " LIMIT 0, 5 "
);

while(submissions.next()) {
	submissions.put("submitted_at", !"".equals(submissions.s("submit_date")) ? m.time("yyyy.MM.dd HH:mm", submissions.s("submit_date")) : "-");
	submissions.put("confirmed", "Y".equals(submissions.s("confirm_yn")));
	submissions.put("course_id_conv", submissions.i("course_id") + "");
}

//=========================
// 4) 최근 Q&A(상위 5개)
//=========================

DataSet qnas = post.query(
	" SELECT p.id post_id, p.course_id, p.subject, p.proc_status, p.reg_date "
	+ " , u.user_nm, u.login_id "
	+ " , c.course_nm "
	+ " , CASE WHEN IFNULL(c.etc2, '') = 'HAKSA_MAPPED' THEN 'haksa' ELSE 'prism' END source_type "
	+ " FROM " + post.table + " p "
	+ " INNER JOIN " + board.table + " b ON b.id = p.board_id AND b.site_id = " + siteId + " AND b.status = 1 AND b.code = 'qna' "
	+ " INNER JOIN " + user.table + " u ON u.id = p.user_id AND u.status != -1 "
	+ " INNER JOIN " + course.table + " c ON c.id = p.course_id AND c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ (!isAdmin ? (" INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ") : "")
	+ " WHERE p.site_id = " + siteId + " AND p.depth = 'A' AND p.display_yn = 'Y' AND p.status != -1 "
	+ " ORDER BY (CASE WHEN p.proc_status = 1 THEN 1 ELSE 0 END) ASC, p.reg_date DESC "
	+ " LIMIT 0, 5 "
);

while(qnas.next()) {
	qnas.put("reg_date_conv", !"".equals(qnas.s("reg_date")) ? m.time("yyyy.MM.dd HH:mm", qnas.s("reg_date")) : "-");
	qnas.put("answered", 1 == qnas.i("proc_status"));
}

//=========================
// 응답
//=========================

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", stats);
result.put("rst_courses", courses);
result.put("rst_submissions", submissions);
result.put("rst_qna", qnas);
result.print();

%>
