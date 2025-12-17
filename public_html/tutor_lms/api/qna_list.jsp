<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > Q&A 탭에서, 과목 Q&A(질문/답변 상태)를 운영 DB 기준으로 조회해야 합니다.

int courseId = m.ri("course_id");
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
	result.print();
	return;
}

String keyword = m.rs("s_keyword");

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
	//왜: 과목 생성 시 기본 게시판 생성이 실패한 환경도 있을 수 있으므로, 빈 목록으로 처리합니다.
	result.put("rst_code", "0000");
	result.put("rst_message", "성공");
	result.put("rst_count", 0);
	result.put("rst_data", new DataSet());
	result.print();
	return;
}

ArrayList<Object> params = new ArrayList<Object>();
String where = "";
if(!"".equals(keyword)) {
	where += " AND (a.subject LIKE ? OR a.content LIKE ? OR u.user_nm LIKE ? OR u.login_id LIKE ?) ";
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
}

DataSet list = post.query(
	" SELECT a.id, a.subject, a.content, a.proc_status, a.reg_date "
	+ " , u.user_nm, u.login_id "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id "
	+ " WHERE a.site_id = " + siteId + " AND a.course_id = " + courseId + " AND a.board_id = " + binfo.i("id") + " "
	+ " AND a.depth = 'A' AND a.display_yn = 'Y' AND a.status != -1 "
	+ where
	+ " ORDER BY a.thread DESC, a.depth ASC, a.id DESC "
	, params.toArray()
);

while(list.next()) {
	list.put("reg_date_conv", !"".equals(list.s("reg_date")) ? m.time("yyyy.MM.dd", list.s("reg_date")) : "-");
	list.put("answered", 1 == list.i("proc_status"));
	list.put("question_conv", m.cutString(m.htmlToText(list.s("content")), 200));
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

