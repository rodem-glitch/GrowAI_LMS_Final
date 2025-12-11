<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserDeptDao userDept = new UserDeptDao();

CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
LmCategoryDao lmCategory = new LmCategoryDao("course");

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

//목록-수강중인과정
DataSet courses = courseUser.query(
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
while(courses.next()) {
	courses.put("start_date_conv", m.time(_message.get("format.date.dot"), courses.s("start_date")));
	courses.put("end_date_conv", m.time(_message.get("format.date.dot"), courses.s("end_date")));
	courses.put("study_date_conv", m.time(_message.get("format.date.dot"), courses.s("start_date")) + " - " + m.time(_message.get("format.date.dot"), courses.s("end_date")));
	courses.put("course_nm_conv", m.cutString(m.htt(courses.s("course_nm")), 60));
	courses.put("progress_ratio_conv", m.nf(courses.d("progress_ratio"), 0));
	courses.put("total_score", m.nf(courses.d("total_score"), 1).replace(".0", ""));
	courses.put("type_conv", "A".equals(courses.s("course_type")) ? "상시" : "정규");
	courses.put("onoff_type_conv", m.getValue(courses.s("onoff_type"), course.onoffTypesMsg));
	courses.put("credit", courses.i("credit"));
	courses.put("mobile_block", courses.b("mobile_yn"));

	courses.put("renew_block", courseUser.setRenewBlock(courses.getRow()));

	if(!"".equals(courses.s("course_file"))) {
		courses.put("course_file_url", m.getUploadUrl(courses.s("course_file")));
	} else {
		courses.put("course_file_url", "/html/images/common/noimage_course.gif");
	}

	String status = "";
	boolean isOpen = false;
	boolean isCancel = false;
	if(courses.i("status") == 0) {
		status = _message.get("list.course_user.etc.waiting_approve");
		if(0 == courses.i("order_id")) isCancel = true;
	} else if(0 > m.diffDate("D", courses.s("start_date"), today)) {
		status = _message.get("list.course_user.etc.waiting_learning");
		//if(0 == courses.i("order_id")) isCancel = true;
		isCancel = true;
	} else {
		if(courses.b("complete_yn")) {
			status = _message.get("list.course_user.etc.complete_success");
		} else {
			status = _message.get("list.course_user.etc.learning");
			//if(0 == courses.i("order_id") && "A".equals(courses.s("course_type"))) isCancel = true;
			if(0 == courses.i("order_id")) isCancel = true;
		}
		isOpen = true;
	}

	courses.put("status_conv", status);
	courses.put("open_block", isOpen);
	courses.put("cancel_block", isCancel);
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
p.setLoop("courses", courses);
p.setLoop("books", books);
p.setLoop("qna_list", qnaList);
p.setLoop("notice_list", noticeList);
p.setLoop("posts", posts);
p.setLoop("messages", messages);

p.display();

%>