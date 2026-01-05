<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

// -------------------------------------------------------------------
// 목적: /mypage/new_main 전용 신규 메인 페이지(Full-screen)
// 레이아웃: GrowAI 스타일 (히어로 섹션, 필터 탭, 카드 그리드)
// -------------------------------------------------------------------

//객체
UserDeptDao userDept = new UserDeptDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
LmCategoryDao lmCategory = new LmCategoryDao("course");

PolyStudentDao polyStudent = new PolyStudentDao();
PolyCourseDao polyCourse = new PolyCourseDao();
PolyMemberKeyDao polyMemberKey = new PolyMemberKeyDao();

BoardDao board = new BoardDao();
PostDao post = new PostDao();
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();

//변수
String today = m.time("yyyyMMdd");

//목록-수강중인과정(비정규/LMS)
DataSet coursesPrism = courseUser.query(
	" SELECT a.*, c.year, c.step, c.course_nm, c.course_type, c.onoff_type, c.course_file, c.credit "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " WHERE a.user_id = " + userId + " AND a.status IN (1, 3) "
	+ " AND IFNULL(c.etc2, '') != 'HAKSA_MAPPED' "
	+ " AND a.close_yn = 'N' AND a.end_date >= '" + today + "' "
	+ " ORDER BY a.start_date DESC, a.id DESC "
	, 6
);
while(coursesPrism.next()) {
	coursesPrism.put("start_date_conv", m.time(_message.get("format.date.dot"), coursesPrism.s("start_date")));
	coursesPrism.put("end_date_conv", m.time(_message.get("format.date.dot"), coursesPrism.s("end_date")));
	coursesPrism.put("study_date_conv", m.time(_message.get("format.date.dot"), coursesPrism.s("start_date")) + " - " + m.time(_message.get("format.date.dot"), coursesPrism.s("end_date")));
	coursesPrism.put("course_nm_conv", m.cutString(m.htt(coursesPrism.s("course_nm")), 40));
	coursesPrism.put("progress_ratio_conv", m.nf(coursesPrism.d("progress_ratio"), 0));

	if(!"".equals(coursesPrism.s("course_file"))) {
		coursesPrism.put("course_file_url", m.getUploadUrl(coursesPrism.s("course_file")));
	} else {
		coursesPrism.put("course_file_url", "/html/images/common/noimage_course.gif");
	}
}

//===== 정규(학사) 수강중인 과정 =====
String memberKey = "";
DataSet memberKeyInfo = polyMemberKey.find("alias_key = '" + uinfo.s("login_id") + "'");
if(memberKeyInfo.next()) {
	memberKey = memberKeyInfo.s("member_key");
} else {
	memberKey = uinfo.s("login_id");
}

String currentYear = m.time("yyyy");
DataSet coursesHaksa = polyStudent.query(
	" SELECT s.*, c.course_name, c.course_ename, c.dept_name, c.grad_name, c.week, c.grade "
	+ " , c.curriculum_name, c.category, c.startdate, c.enddate, c.hour1, c.classroom "
	+ " FROM " + polyStudent.table + " s "
	+ " INNER JOIN " + polyCourse.table + " c ON s.course_code = c.course_code "
	+ "   AND s.open_year = c.open_year AND s.open_term = c.open_term "
	+ "   AND s.bunban_code = c.bunban_code AND s.group_code = c.group_code "
	+ " WHERE s.member_key = '" + memberKey + "' "
	+ " AND s.open_year = '" + currentYear + "' "
	+ " ORDER BY c.startdate DESC, c.course_name ASC "
	, 6
);
while(coursesHaksa.next()) {
	String startdate = coursesHaksa.s("startdate");
	String enddate = coursesHaksa.s("enddate");
	if(startdate.length() >= 8) {
		coursesHaksa.put("start_date_conv", m.time(_message.get("format.date.dot"), startdate));
	} else {
		coursesHaksa.put("start_date_conv", startdate);
	}
	if(enddate.length() >= 8) {
		coursesHaksa.put("end_date_conv", m.time(_message.get("format.date.dot"), enddate));
	} else {
		coursesHaksa.put("end_date_conv", enddate);
	}
	coursesHaksa.put("study_date_conv", coursesHaksa.s("start_date_conv") + " - " + coursesHaksa.s("end_date_conv"));
	coursesHaksa.put("course_nm_conv", m.cutString(coursesHaksa.s("course_name"), 40));
	coursesHaksa.put("onoff_type_conv", "".equals(coursesHaksa.s("category")) ? "정규" : coursesHaksa.s("category"));
	
	String haksaCuid = coursesHaksa.s("course_code") + "_" + coursesHaksa.s("open_year") 
		+ "_" + coursesHaksa.s("open_term") + "_" + coursesHaksa.s("bunban_code") + "_" + coursesHaksa.s("group_code");
	coursesHaksa.put("haksa_cuid", haksaCuid);
}

//목록-QNA
DataSet qnaList = post.query(
	" ( SELECT a.id, 0 course_user_id, a.subject, a.proc_status, a.reg_date, b.board_nm, b.code "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.board_type = 'qna' AND b.site_id = " + siteId + " "
	+ " WHERE a.display_yn = 'Y' AND a.status = 1 AND a.user_id = " + userId + " AND a.depth = 'A' ORDER BY a.reg_date DESC LIMIT 5 ) "
	+ " UNION " 
	+ " ( SELECT a.id, a.course_user_id, a.subject, a.proc_status, a.reg_date, c.course_nm board_nm, b.code "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.board_type = 'qna' AND b.site_id = " + siteId + " "
	+ " LEFT JOIN " + course.table + " c ON b.course_id = c.id AND c.site_id = " + siteId + " AND c.status != -1 "
	+ " WHERE a.display_yn = 'Y' AND a.status = 1 AND a.user_id = " + userId + " AND a.depth = 'A' ORDER BY a.reg_date DESC LIMIT 5 ) "
	+ " ORDER BY reg_date DESC "
);
while(qnaList.next()) {
	qnaList.put("subject_conv", m.cutString(qnaList.s("subject"), 50));
	qnaList.put("reg_date_conv", m.time(_message.get("format.date.dot"), qnaList.s("reg_date")));
	qnaList.put("proc_status_conv", m.getValue(qnaList.s("proc_status"), post.procStatusListMsg));
}

//공지사항 목록
DataSet noticeList = post.query(
		"SELECT a.id, a.subject, a.reg_date " +
		" FROM " + clPost.table + " a " +
		" WHERE a.board_cd = 'notice' and a.display_yn = 'Y' AND a.status = 1 AND a.depth = 'A' " +
		" AND exists (select 1 from " + courseUser.table + " b where b.user_id = " + userId + " and b.course_id = a.course_id) " +
		" ORDER BY reg_date DESC LIMIT 5"
);
while(noticeList.next()) {
	noticeList.put("subject_conv", m.cutString(noticeList.s("subject"), 50));
	noticeList.put("reg_date_conv", m.time(_message.get("format.date.dot"), noticeList.s("reg_date")));
}

// 레이아웃: blank (전역 네비게이션 제외)
p.setLayout("blank");
p.setBody("mypage.new_main_full");

p.setVar("p_title", "미래형 직업교육 플랫폼");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("user", uinfo);

p.setLoop("courses_prism", coursesPrism);
p.setLoop("courses_haksa", coursesHaksa);
p.setLoop("qna_list", qnaList);
p.setLoop("notice_list", noticeList);

p.display();

%>
