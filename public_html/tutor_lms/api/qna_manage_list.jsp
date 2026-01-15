<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- Q&A 통합관리 화면에서 과목 구분 없이 질문 목록을 한 번에 확인해야 합니다.
//- 페이지/필터 영향을 받지 않도록 서버에서 통합 리스트를 제공합니다.

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
ClBoardDao board = new ClBoardDao(siteId);
ClPostDao post = new ClPostDao();
UserDao user = new UserDao();

String keyword = m.rs("s_keyword");
String safeKeyword = m.replace(keyword, "'", "''");
String startDate = m.rs("start_date");
String endDate = m.rs("end_date");
String status = m.rs("status"); // unanswered/answered
int pageNo = m.ri("page", 1);
int pageSize = m.ri("page_size", 20);
if(pageNo < 1) pageNo = 1;
if(pageSize != 20 && pageSize != 50 && pageSize != 100) pageSize = 20;
int offset = (pageNo - 1) * pageSize;

String joinTutor = "";
if(!isAdmin) {
	joinTutor = " INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id "
		+ " AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ";
}

String keywordWhere = "";
if(!"".equals(safeKeyword)) {
	keywordWhere = " AND (p.subject LIKE '%" + safeKeyword + "%' "
		+ " OR c.course_nm LIKE '%" + safeKeyword + "%' "
		+ " OR u.user_nm LIKE '%" + safeKeyword + "%' "
		+ " OR u.login_id LIKE '%" + safeKeyword + "%') ";
}

String dateWhere = "";
if(!"".equals(startDate)) {
	dateWhere += " AND p.reg_date >= '" + m.time("yyyyMMdd", startDate) + "000000' ";
}
if(!"".equals(endDate)) {
	dateWhere += " AND p.reg_date <= '" + m.time("yyyyMMdd", endDate) + "235959' ";
}

String statusWhere = "";
if("unanswered".equals(status)) {
	statusWhere = " AND p.proc_status != 1 ";
} else if("answered".equals(status)) {
	statusWhere = " AND p.proc_status = 1 ";
}

int totalCount = post.getOneInt(
	" SELECT COUNT(*) "
	+ " FROM " + post.table + " p "
	+ " INNER JOIN " + board.table + " b ON b.id = p.board_id AND b.site_id = " + siteId + " AND b.status = 1 AND b.code = 'qna' "
	+ " INNER JOIN " + user.table + " u ON u.id = p.user_id AND u.status != -1 "
	+ " INNER JOIN " + course.table + " c ON c.id = p.course_id AND c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ joinTutor
	+ " WHERE p.site_id = " + siteId + " AND p.depth = 'A' AND p.display_yn = 'Y' AND p.status != -1 "
	+ keywordWhere
	+ dateWhere
	+ statusWhere
);

DataSet list = post.query(
	" SELECT p.id post_id, p.course_id, p.subject, p.proc_status, p.reg_date "
	+ " , u.user_nm, u.login_id "
	+ " , c.course_nm "
	+ " , CASE WHEN IFNULL(c.etc2, '') = 'HAKSA_MAPPED' THEN 'haksa' ELSE 'prism' END source_type "
	+ " FROM " + post.table + " p "
	+ " INNER JOIN " + board.table + " b ON b.id = p.board_id AND b.site_id = " + siteId + " AND b.status = 1 AND b.code = 'qna' "
	+ " INNER JOIN " + user.table + " u ON u.id = p.user_id AND u.status != -1 "
	+ " INNER JOIN " + course.table + " c ON c.id = p.course_id AND c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' "
	+ joinTutor
	+ " WHERE p.site_id = " + siteId + " AND p.depth = 'A' AND p.display_yn = 'Y' AND p.status != -1 "
	+ keywordWhere
	+ dateWhere
	+ statusWhere
	+ " ORDER BY (CASE WHEN p.proc_status = 1 THEN 1 ELSE 0 END) ASC, p.reg_date DESC "
	+ " LIMIT " + offset + ", " + pageSize + " "
);

while(list.next()) {
	list.put("reg_date_conv", !"".equals(list.s("reg_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("reg_date")) : "-");
	list.put("answered", 1 == list.i("proc_status"));
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_total", totalCount);
result.put("rst_page", pageNo);
result.put("rst_limit", pageSize);
result.put("rst_data", list);
result.print();

%>
