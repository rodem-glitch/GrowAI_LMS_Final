<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
BoardDao board = new BoardDao();
PostDao post = new PostDao();
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();

//제한-회원
if(1 > user.findCount("id = ? AND site_id = " + siteId + " AND status != -1", new Object[] {uid})) { m.jsAlert("해당 회원정보가 없습니다."); return; }

//변수
String today = m.time("yyyyMMdd");

//요약
int courseCnt = courseUser.getOneInt(
	" SELECT COUNT(*) FROM " + courseUser.table + " "
	+ " WHERE user_id = '" + uid + "' AND status IN (1,3) "
);
int qnaCnt = post.getOneInt(
	" SELECT COUNT(*) FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON b.id = a.board_id AND b.board_type = 'qna' AND b.status = 1 "
	+ " WHERE a.user_id = " + uid + " AND a.status = 1 AND a.depth = 'A' "
);
int qnaComplCnt = post.getOneInt(
	" SELECT COUNT(*) FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON b.id = a.board_id AND b.board_type = 'qna' AND b.status = 1 "
	+ " WHERE a.user_id = " + uid + " AND a.status = 1 AND a.depth = 'A' AND a.proc_status = 1 "
);
int qnaReadyCnt = qnaCnt - qnaComplCnt;

int clQnaCnt = clPost.getOneInt(
	" SELECT COUNT(*) FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON b.id = a.board_id AND b.code = 'qna' AND b.status = 1 "
	+ " WHERE a.user_id = " + uid + " AND a.status = 1 AND a.depth = 'A' "
);
int clQnaComplCnt = clPost.getOneInt(
	" SELECT COUNT(*) FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON b.id = a.board_id AND b.code = 'qna' AND b.status = 1 "
	+ " WHERE a.user_id = " + uid + " AND a.status = 1 AND a.depth = 'A' AND a.proc_status = 1 "
);
int clQnaReadyCnt = clQnaCnt - clQnaComplCnt;

DataSet stat = new DataSet(); stat.addRow();
stat.put("course_cnt", m.nf(courseCnt));
stat.put("qna_cnt", m.nf(qnaCnt));
stat.put("qna_compl_cnt", m.nf(qnaComplCnt));
stat.put("qna_ready_cnt", m.nf(qnaReadyCnt));
stat.put("qna_class", qnaReadyCnt > 0 ? "qna_ready" : "qna_normal");
stat.put("cl_qna_cnt", m.nf(clQnaCnt));
stat.put("cl_qna_compl_cnt", m.nf(clQnaComplCnt));
stat.put("cl_qna_ready_cnt", m.nf(clQnaReadyCnt));
stat.put("cl_qna_class", clQnaReadyCnt > 0 ? "qna_ready" : "qna_normal");

//QNA목록
DataSet qlist = post.query(
	"SELECT a.*, b.board_nm, u.login_id "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.board_type = 'qna' AND b.status = 1 "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.user_id = " + uid + " AND a.status = 1 AND a.depth = 'A' "
	+ " ORDER BY a.thread ASC, a.depth ASC "
	, 5
);
while(qlist.next()) {
	qlist.put("subject_conv", m.cutString(qlist.s("subject"), 70));
	qlist.put("board_nm_conv", m.cutString(qlist.s("board_nm"), 20));
	qlist.put("new_block", m.diffDate("H", qlist.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	qlist.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", qlist.s("reg_date")));
	qlist.put("hit_cnt_conv", m.nf(qlist.getInt("hit_cnt")));
	qlist.put("proc_status_conv", m.getItem(qlist.s("proc_status"), clPost.procStatusList));
}

//과정QNA목록
DataSet cqlist = clPost.query(
	"SELECT a.*, b.board_nm, u.login_id, c.course_nm "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.code = 'qna' AND b.status = 1 "
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.user_id = " + uid + " AND a.status = 1 AND a.depth = 'A' "
	+ " ORDER BY a.thread ASC, a.depth ASC "
	, 5
);
while(cqlist.next()) {
	cqlist.put("subject_conv", m.cutString(cqlist.s("subject"), 70));
	cqlist.put("course_nm_conv", m.cutString(cqlist.s("course_nm"), 20));
	cqlist.put("new_block", m.diffDate("H", cqlist.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	cqlist.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", cqlist.s("reg_date")));
	cqlist.put("hit_cnt_conv", m.nf(cqlist.getInt("hit_cnt")));
	cqlist.put("proc_status_conv", m.getItem(cqlist.s("proc_status"), clPost.procStatusList));
}

//수강목록
DataSet courses = courseUser.query(
	"SELECT a.*, c.course_nm, c.course_type, c.year, c.step "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " WHERE a.user_id = " + uid + " AND a.status IN (1, 3) "
	+ " ORDER BY a.start_date DESC, a.id DESC "
	, 5
);
while(courses.next()) {
	courses.put("start_date_conv", m.time("yyyy.MM.dd", courses.s("start_date")));
	courses.put("end_date_conv", m.time("yyyy.MM.dd", courses.s("end_date")));
	courses.put("ready_block", courses.i("status") == 0);
	courses.put("course_nm_conv", m.cutString(courses.s("course_nm"), 50));
	courses.put("progress_ratio", m.nf(courses.d("progress_ratio"), 1));
	courses.put("total_score", m.nf(courses.d("total_score"), 1));
	courses.put("type_conv", m.getItem(courses.s("course_type"), course.types));

	String status = "-";
	if(courses.b("close_yn")) status = "마감";
	else if(!"".equals(courses.s("complete_yn")) && courses.b("complete_yn")) status = "수료";
	else if(!"".equals(courses.s("complete_yn")) && !courses.b("complete_yn")) status = "미수료";
	else if("".equals(courses.s("complete_yn"))) {
		if(0 > m.diffDate("D", courses.s("start_date"), today)) status = "대기중";
		else if(0 < m.diffDate("D", courses.s("end_date"), today)) status = "학습종료";
		else status = "학습중";
	}
	courses.put("status_conv", status);
}


//출력
p.setLayout(ch);
p.setBody("crm.main");
p.setVar("query", m.qs());

p.setVar("stat", stat);
p.setLoop("qna_list", qlist);
p.setLoop("cl_qna_list", cqlist);
p.setLoop("courses", courses);

p.setVar("tab_total", "current");
p.display();

%>