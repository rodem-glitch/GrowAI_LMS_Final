<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(91, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체

//출력
p.setBody("main.manual");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.display();

%>