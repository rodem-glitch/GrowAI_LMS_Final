<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!Menu.accessible(91, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//출력
p.setLayout(null);
p.setBody("design.mainpage_modules." + m.rs("type"));
p.display();

%>