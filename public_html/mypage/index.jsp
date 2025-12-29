<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserDeptDao userDept = new UserDeptDao();

CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
LmCategoryDao lmCategory = new LmCategoryDao("course");

PolyStudentDao polyStudent = new PolyStudentDao();
PolyCourseDao polyCourse = new PolyCourseDao();
PolyMemberKeyDao polyMemberKey = new PolyMemberKeyDao();

BookDao book = new BookDao();
BookUserDao bookUser = new BookUserDao();

MessageUserDao messageUser = new MessageUserDao();
MessageDao message = new MessageDao();

OrderDao order = new OrderDao();
PaymentDao payment = new PaymentDao();

BoardDao board = new BoardDao();
PostDao post = new PostDao();
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
CategoryDao category = new CategoryDao();

//변수
String type = m.rs("type");
String today = m.time("yyyyMMdd");

//목록-수강중인과정(비정규/LMS)
DataSet coursesPrism = courseUser.query(
	" SELECT a.*, c.year, c.step, c.course_nm, c.course_type, c.onoff_type, c.course_file, c.credit, c.lesson_time, c.renew_max_cnt, c.renew_yn, c.mobile_yn, ct.category_nm "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + lmCategory.table + " ct ON c.category_id = ct.id AND ct.module = 'course' AND ct.status = 1 "
	+ " WHERE a.user_id = " + userId + " AND a.status IN (1, 3) "
	+ (!"".equals(type) ? " AND c.onoff_type " + ("on".equals(type) ? "=" : "!=") + " 'N' " : "")
	+ " AND a.close_yn = 'N' AND a.end_date >= '" + today + "' "
	+ " ORDER BY a.start_date DESC, a.id DESC "
	, 10
);
while(coursesPrism.next()) {
	coursesPrism.put("start_date_conv", m.time(_message.get("format.date.dot"), coursesPrism.s("start_date")));
	coursesPrism.put("end_date_conv", m.time(_message.get("format.date.dot"), coursesPrism.s("end_date")));
	coursesPrism.put("study_date_conv", m.time(_message.get("format.date.dot"), coursesPrism.s("start_date")) + " - " + m.time(_message.get("format.date.dot"), coursesPrism.s("end_date")));
	coursesPrism.put("course_nm_conv", m.cutString(m.htt(coursesPrism.s("course_nm")), 60));
	coursesPrism.put("progress_ratio_conv", m.nf(coursesPrism.d("progress_ratio"), 0));
	coursesPrism.put("total_score", m.nf(coursesPrism.d("total_score"), 1).replace(".0", ""));
	coursesPrism.put("type_conv", "A".equals(coursesPrism.s("course_type")) ? "상시" : "정규");
	coursesPrism.put("onoff_type_conv", m.getValue(coursesPrism.s("onoff_type"), course.onoffTypesMsg));
	coursesPrism.put("credit", coursesPrism.i("credit"));
	coursesPrism.put("mobile_block", coursesPrism.b("mobile_yn"));

	coursesPrism.put("renew_block", courseUser.setRenewBlock(coursesPrism.getRow()));

	if(!"".equals(coursesPrism.s("course_file"))) {
		coursesPrism.put("course_file_url", m.getUploadUrl(coursesPrism.s("course_file")));
	} else {
		coursesPrism.put("course_file_url", "/html/images/common/noimage_course.gif");
	}

	String status = "";
	boolean isOpen = false;
	boolean isCancel = false;
	if(coursesPrism.i("status") == 0) {
		status = _message.get("list.course_user.etc.waiting_approve");
		if(0 == coursesPrism.i("order_id")) isCancel = true;
	} else if(0 > m.diffDate("D", coursesPrism.s("start_date"), today)) {
		status = _message.get("list.course_user.etc.waiting_learning");
		isCancel = true;
	} else {
		if(coursesPrism.b("complete_yn")) {
			status = _message.get("list.course_user.etc.complete_success");
		} else {
			status = _message.get("list.course_user.etc.learning");
			if(0 == coursesPrism.i("order_id")) isCancel = true;
		}
		isOpen = true;
	}

	coursesPrism.put("status_conv", status);
	coursesPrism.put("open_block", isOpen);
	coursesPrism.put("cancel_block", isCancel);
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
	, 10
);
while(coursesHaksa.next()) {
	// 학습기간 변환
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
	coursesHaksa.put("progress_ratio_conv", "0");
	coursesHaksa.put("status_conv", "학습중");
	coursesHaksa.put("open_block", true);
	coursesHaksa.put("source_type", "haksa");
	coursesHaksa.put("onoff_type_conv", "".equals(coursesHaksa.s("category")) ? "정규" : coursesHaksa.s("category"));
	
	String haksaCuid = coursesHaksa.s("course_code") + "_" + coursesHaksa.s("open_year") 
		+ "_" + coursesHaksa.s("open_term") + "_" + coursesHaksa.s("bunban_code");
	coursesHaksa.put("haksa_cuid", haksaCuid);
}

uinfo.put("dept_nm_conv", 0 < uinfo.i("dept_id") ? userDept.getNames(uinfo.i("dept_id")) : "-");
uinfo.put("email_conv", !"".equals(uinfo.s("email")) ? uinfo.s("email") : "-");
uinfo.put("mobile_conv", !"".equals(uinfo.s("mobile_conv")) ? uinfo.s("mobile_conv") : "-");
uinfo.put("birthday_conv", !"".equals(uinfo.s("birthday")) ? m.time(_message.get("format.date.local"), uinfo.s("birthday")) : "-");

//목록-대여중인도서
DataSet books = bookUser.query(
	"SELECT a.*, b.book_nm "
	+ " FROM " + bookUser.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
	+ " WHERE a.user_id = " + userId + " AND a.status IN (1, 3) "
	+ " AND (a.permanent_yn = 'Y' OR '" + today + "' BETWEEN a.start_date AND a.end_date) "
	+ " ORDER BY a.start_date ASC, a.id DESC "
	, 10
);
while(books.next()) {
	books.put("book_nm_conv", m.cutString(m.htt(books.s("book_nm")), 60));
	books.put("study_date_conv", m.time(_message.get("format.date.dot"), books.s("start_date")) + " - " + m.time(_message.get("format.date.dot"), books.s("end_date")));
}

//목록-QNA
DataSet qnaList = post.query(
	" ( SELECT a.id, 0 course_user_id, a.subject, a.proc_status, a.reg_date, b.board_nm, b.code "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.board_type = 'qna' AND b.site_id = " + siteId + " "
	+ " WHERE a.display_yn = 'Y' AND a.status = 1 AND a.user_id = " + userId + " AND a.depth = 'A' ORDER BY a.reg_date DESC LIMIT 10 ) "
	+ " UNION " 
	+ " ( SELECT a.id, a.course_user_id, a.subject, a.proc_status, a.reg_date, c.course_nm board_nm, b.code "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.board_type = 'qna' AND b.site_id = " + siteId + " "
	+ " LEFT JOIN " + course.table + " c ON b.course_id = c.id AND c.site_id = " + siteId + " AND c.status != -1 "
	+ " WHERE a.display_yn = 'Y' AND a.status = 1 AND a.user_id = " + userId + " AND a.depth = 'A' ORDER BY a.reg_date DESC LIMIT 10 ) "
	+ " ORDER BY reg_date DESC "
	//, 20
);
while(qnaList.next()) {
	qnaList.put("subject_conv", m.cutString(qnaList.s("subject"), 60));
	qnaList.put("reg_date_conv", m.time(_message.get("format.date.dot"), qnaList.s("reg_date")));
	//qnaList.put("mod_date_conv", m.time(_message.get("format.date.dot"), qnaList.s("mod_date")));
	qnaList.put("proc_status_conv", m.getValue(qnaList.s("proc_status"), post.procStatusListMsg));
}

//공지사항 목록 (수강 중인 모든 과정의 공지사항)
DataSet noticeList = post.query(
		"SELECT a.id, a.subject, a.reg_date " +
		" FROM " + clPost.table + " a " +
		" WHERE a.board_cd = 'notice' and a.display_yn = 'Y' AND a.status = 1 AND a.depth = 'A' " +
		" AND exists (select 1 from " + courseUser.table + " b where b.user_id = " + userId + " and b.course_id = a.course_id) " +
		" ORDER BY reg_date DESC LIMIT 4"
);
//m.p(post.getQuery());
while(noticeList.next()) {
	noticeList.put("subject_conv", m.cutString(noticeList.s("subject"), 60));
	noticeList.put("reg_date_conv", m.time(_message.get("format.date.dot"), noticeList.s("reg_date")));
}

//목록-내게시물
DataSet posts = post.query(
	"SELECT a.*, b.board_nm, b.code, c.category_nm "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.board_type != 'qna' AND b.site_id = " + siteId + " "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
	+ " WHERE a.display_yn = 'Y' AND a.status = 1 AND a.user_id = " + userId + " AND a.depth = 'A' "
	+ " ORDER BY a.thread DESC "
	, 20
);
while(posts.next()) {
	posts.put("subject_conv", m.cutString(posts.s("subject"), 60));
	posts.put("reg_date_conv", m.time(_message.get("format.date.dot"), posts.s("reg_date")));
	posts.put("mod_date_conv", m.time(_message.get("format.date.dot"), posts.s("mod_date")));
	posts.put("hit_cnt_conv", m.nf(posts.i("hit_cnt")));
	posts.put("recomm_cnt_conv", m.nf(posts.i("recomm_cnt")));
}

//목록-쪽지
DataSet messages = messageUser.query(
	"SELECT a.*, b.subject "
	+ " FROM " + messageUser.table + " a "
	+ " INNER JOIN " + message.table + " b ON b.id = a.message_id AND b.status = 1 AND b.site_id = " + siteId + " "
	+ " WHERE a.user_id = " + userId + " AND a.status = 1 "
	+ " ORDER BY a.reg_date DESC "
	, 5
);
while(messages.next()) {
	messages.put("subject_conv", m.cutString(messages.s("subject"), 30));
	messages.put("img_str", "Y".equals(messages.s("read_yn")) ? "_on" : "_off");
	messages.put("reg_date_conv", m.time(_message.get("format.date.dot"), messages.s("reg_date")));
}

//출력
p.setLayout(ch);
p.setBody("mypage.index");
p.setVar("p_title", "나의 강의실");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("user", uinfo);
p.setLoop("courses_haksa", coursesHaksa);
p.setLoop("courses_prism", coursesPrism);
p.setLoop("books", books);
p.setLoop("qna_list", qnaList);
p.setLoop("notice_list", noticeList);
p.setLoop("posts", posts);
p.setLoop("messages", messages);

p.display();

%>