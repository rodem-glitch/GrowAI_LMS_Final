<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
ClFileDao clFile = new ClFileDao();

int boardId = clBoard.getOneInt("SELECT id FROM " + clBoard.table + " WHERE course_id = " + courseId + " AND board_type = 4");

if(boardId == 0) { m.jsError(_message.get("alert.board.nodata")); return; }

DataSet info = clPost.find("id = " + id + " AND course_user_id = " + cuid + " AND display_yn = 'Y' AND status = 1 AND course_id = " + courseId + " AND board_id = " + boardId);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("point", info.i("point"), "hname:'별점', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
//f.addElement("public_yn", info.s("public_yn"), "hname:'공개여부', required:'Y'");

//수정
if(m.isPost() && f.validate()) {

	clPost.item("subject", f.get("subject"));
	clPost.item("content", f.get("content"));
	clPost.item("point", f.getInt("point"));
	clPost.item("mod_date", m.time("yyyyMMddHHmmss"));

	if(!clPost.update("id = " + id)) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	m.jsReplace("review_view.jsp?" + m.qs("mode"), "parent");
	return;
}

info.put("content", m.htt(info.s("content")));

//출력
p.setLayout(ch);
p.setBody("classroom.review_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setVar("active_epil", "select");
p.display();

%>