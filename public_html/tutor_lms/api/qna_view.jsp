<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > Q&A 상세/답변 화면에서, 질문과 답변 내용을 함께 조회해야 합니다.

int courseId = m.ri("course_id");
int postId = m.ri("post_id");
if(0 == courseId || 0 == postId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, post_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseDao course = new CourseDao();
ClBoardDao board = new ClBoardDao(siteId);
ClPostDao post = new ClPostDao();
UserDao user = new UserDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 Q&A를 조회할 권한이 없습니다.");
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

DataSet binfo = board.find("course_id = " + courseId + " AND site_id = " + siteId + " AND code = 'qna' AND status = 1");
if(!binfo.next()) {
	result.put("rst_code", "4041");
	result.put("rst_message", "Q&A 게시판 정보가 없습니다.");
	result.print();
	return;
}

DataSet info = post.query(
	" SELECT q.id question_id, q.thread, q.depth, q.subject, q.content question_content, q.proc_status, q.reg_date question_reg_date "
	+ " , qu.user_nm question_user_nm, qu.login_id question_login_id "
	+ " , a.id answer_id, a.content answer_content, a.reg_date answer_reg_date, a.mod_date answer_mod_date "
	+ " , au.user_nm answer_user_nm, au.login_id answer_login_id "
	+ " FROM " + post.table + " q "
	+ " INNER JOIN " + user.table + " qu ON qu.id = q.user_id "
	+ " LEFT JOIN " + post.table + " a ON a.id = (SELECT MAX(id) FROM " + post.table + " "
		+ " WHERE thread = q.thread AND depth = 'AA' AND status != -1) "
	+ " LEFT JOIN " + user.table + " au ON au.id = a.user_id "
	+ " WHERE q.site_id = " + siteId + " AND q.course_id = " + courseId + " AND q.board_id = " + binfo.i("id") + " "
	+ " AND q.id = " + postId + " AND q.status != -1 "
);

if(!info.next()) {
	result.put("rst_code", "4042");
	result.put("rst_message", "해당 Q&A 글이 없습니다.");
	result.print();
	return;
}

info.put("question_reg_date_conv", !"".equals(info.s("question_reg_date")) ? m.time("yyyy.MM.dd HH:mm", info.s("question_reg_date")) : "-");
info.put("answered", 1 == info.i("proc_status"));
info.put("answer_reg_date_conv", !"".equals(info.s("answer_reg_date")) ? m.time("yyyy.MM.dd HH:mm", info.s("answer_reg_date")) : "-");

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", info);
result.print();

%>

