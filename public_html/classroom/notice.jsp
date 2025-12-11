<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();

//폼체크
f.addElement("sf", null, null);
f.addElement("sq", null, null);

//목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum(20);
lm.setTable(
	clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
);
lm.setFields("a.*");
lm.addWhere("a.display_yn = 'Y'");
lm.addWhere("a.status = 1");
lm.addWhere("b.board_type = 1");
lm.addWhere("a.course_id = " + courseId + "");
if(!"".equals(f.get("sf"))) lm.addSearch(f.get("sf"), f.get("sq"), "LIKE");
else if("".equals(f.get("sf")) && !"".equals(f.get("sq"))) {
	lm.addSearch("a.subject,a.content", f.get("sq"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.thread, a.depth, a.id DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
//	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("hit_cnt", m.nf(list.i("hit_cnt")));
	list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
}

//출력
p.setLayout(ch);
p.setBody("classroom.notice");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());


p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar("active_notice", "select");
p.display();

%>