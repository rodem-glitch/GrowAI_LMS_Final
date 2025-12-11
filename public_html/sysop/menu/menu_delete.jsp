<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(2, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//아이디
String id = m.rs("id");

//유효성 체크
if("".equals(id)) {
	m.jsError("아이디는 반드시 지정해야 합니다.");
	return;
}

//객체
MenuDao menu = new MenuDao();
//menu.setDebug(out);

//정보 검사(메뉴)
DataSet info = menu.get(id);
if(!info.next()) {
	m.jsError("해당 정보가 없습니다.");
	return;
}

//하위메뉴 존재여부 확인
if(menu.findCount("parent_id = " + id + "") > 0) {
	m.jsError("하위메뉴가 존재합니다.\\n하위메뉴부터 삭제해주세요.");
	return;
}

//삭제(진짜 삭제)
if(!menu.delete("id = " + id + "")) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

out.print("<script>parent.left.location.reload();</script>");
m.jsReplace("menu_insert.jsp");

%>