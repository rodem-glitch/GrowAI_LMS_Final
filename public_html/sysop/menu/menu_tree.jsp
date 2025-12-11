<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(2, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
String type = m.rs("type", "ADMIN");
if("".equals(type)) type = "ADMIN";

//객체
MenuDao menu = new MenuDao();

//목록
DataSet list = menu.getList(type);
while(list.next()) {
	list.put("parent_id", "".equals(list.s("parent_id")) ? "-" : list.s("parent_id"));
	list.put("name", m.addSlashes(list.s("menu_nm")));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "메뉴관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "id=>아이디", "menu_nm=>메뉴명", "link=>링크", "depth=>DEPTH", "sort=>순서", "display_yn=>노출여부" }, "메뉴관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}


//출력
p.setLayout("blank");
p.setBody("menu.menu_tree");
p.setVar("p_title", "관리자 메뉴");

p.setLoop("list", list);
p.display();

%>