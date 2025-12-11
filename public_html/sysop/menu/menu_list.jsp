<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(2, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//타입
String type = m.rs("type", "ADMIN");

//출력
//p.setDebug(out);
p.setLayout(ch);
p.setBody("menu.menu_list");
p.setVar("p_title", "메뉴관리");
p.setVar("tab_class_" + type , "current");
p.setVar("admin_menu_block", "ADMIN".equals(type));
p.setVar("query", m.qs());
p.display();

%>