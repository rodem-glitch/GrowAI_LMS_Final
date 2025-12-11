<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(92, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//출력
p.setBody("manual.manual_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.display();

%>