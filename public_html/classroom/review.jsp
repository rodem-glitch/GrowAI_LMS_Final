<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
ClFileDao clFile = new ClFileDao();

int boardId = clBoard.getOneInt("SELECT id FROM " + clBoard.table + " WHERE course_id = " + courseId + " AND board_type = 4");

if(boardId == 0) { m.jsError(_message.get("alert.board.nodata")); return; }

//폼체크
f.addElement("sf", null, null);
f.addElement("sq", null, null);

//목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum(20);
lm.setTable(
	clPost.table + " a"
	+ " INNER JOIN " + cu.table + " e ON e.id = a.course_user_id AND e.status IN ( 1, 3 ) "
);
lm.setFields("a.*");
lm.addWhere("a.display_yn = 'Y' AND a.status = 1 AND a.course_id = " + courseId + " AND a.board_id = " + boardId);
if(!"".equals(f.get("sf"))) lm.addSearch(f.get("sf"), f.get("sq"), "LIKE");
else if("".equals(f.get("sf")) && !"".equals(f.get("sq"))) {
	lm.addSearch("a.subject,a.content,a.writer", f.get("sq"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.thread, a.depth, a.id DESC");

String on = "<img src='/html/images/common/star_on.jpg'>";
String off = "<img src='/html/images/common/star_off.jpg'>";

DataSet list = lm.getDataSet();
while(list.next()) {
//	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
	list.put("hit_cnt_conv", m.nf(list.getInt("hit_cnt")));
	list.put("point", m.repeatString(on , list.i("point")) + m.repeatString(off , 5 - list.i("point")));
}

//글쓰기 여부????
boolean isWrite = true;

//출력
p.setLayout(ch);
p.setBody("classroom.review");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging())
;
p.setVar("is_write", isWrite);
p.setVar("active_epil", "select");
p.display();

%>