<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String idx = f.get("idx");
if("".equals(idx)) {
	m.jsAlert("기본키는 반드시 지정해야 합니다.");
	m.js("parent.CloseLayer();");
	return;
}

//폼체크
f.addElement("board_cd", null, "hname:'이동할 게시판', required:'Y'");
f.addElement("category_id", null, "hname:'카테고리'");

//이동
if(m.isPost() && f.validate()) {
	//제한
	int moveId = board.getOneInt("SELECT id FROM " + board.table + " WHERE code = ? AND site_id = " + siteId + " AND status != -1", new String[] {f.get("board_cd")});
	if(1 > moveId) {
		m.jsAlert("해당 게시판 정보가 없습니다.");
		m.js("parent.parent.CloseLayer();");
		return;
	}

	post.item("board_id", moveId);
	post.item("category_id", f.getInt("category_id"));
	if(!post.update("id IN (" + idx + ") AND site_id = " + siteId + " AND status != -1")) { m.jsAlert("이동하는 중 오류가 발생했습니다."); return; }
	
	m.jsReplace("index.jsp?code=" + f.get("board_cd") + "&" + m.qs("idx,code"), "parent.parent");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("board.move");
p.setVar("form_script", f.getScript());
p.setVar("p_title", "게시물이동");

p.setLoop("list", board.find("site_id = " + siteId + " AND status != -1"));

p.setVar("binfo", binfo);
p.display();

%>