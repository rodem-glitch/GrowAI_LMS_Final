<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(125, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//출력
//p.setDebug(out);
p.setBody("sitemap.sitemap_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("type", type);
p.display();

%>