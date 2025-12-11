<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
CourseDao course = new CourseDao();

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(
	clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.code = 'qna' AND b.status = 1 "
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1 "
);
lm.setFields("a.*, b.board_nm, u.login_id, c.course_nm");
lm.addWhere("a.user_id = " + uid + "");
lm.addWhere("a.status = 1");
lm.addWhere("a.depth = 'A'");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.thread, a.depth, a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("subject_conv", m.cutString(list.s("subject"), 70));
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 20));
	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("hit_cnt_conv", m.nf(list.getInt("hit_cnt")));
	list.put("proc_status_conv", m.getItem(list.s("proc_status"), clPost.procStatusList));
}

//출력
p.setLayout(ch);
p.setBody("crm.cqna_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("qid"));

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar("tab_qna", "current");
p.setVar("tab_sub_cqna", "current");
p.display();

%>