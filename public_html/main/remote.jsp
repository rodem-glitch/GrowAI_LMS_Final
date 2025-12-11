<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

ch = m.rs("ch", "board");

//출력
p.setLayout(ch);
p.setBody("main.remote");
p.display();

%>