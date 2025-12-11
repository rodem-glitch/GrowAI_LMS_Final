<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//객체
ClPostDao clPost = new ClPostDao();
ClBoardDao clBoard = new ClBoardDao();
CourseDao course = new CourseDao();
UserDao user = new UserDao();

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.code = 'review' "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1 "
);
lm.setFields("a.*, c.course_nm, c.step, c.year, u.login_id");
lm.addWhere("a.display_yn = 'Y'");
lm.addWhere("a.status = 1");
lm.addWhere("a.course_id = " + cid + "");
lm.setOrderBy("a.thread, a.depth, a.id DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("subject_conv", m.cutString(list.s("subject"), 40));
	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
//	list.put("point", m.repeatString(on, list.i("point")) + m.repeatString(off, 5 - list.i("point")));
	list.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(list.s("writer")) : list.s("writer"));
}

//출력
p.setLayout("blank");
p.setBody("course.cpost");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.display();

%>