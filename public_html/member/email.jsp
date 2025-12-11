<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%


//출력
p.setLayout(ch);
p.setBody(ch + ".email");
p.setVar("LNB_EMAIL", "select");
p.display();

%>