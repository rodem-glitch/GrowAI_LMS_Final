<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String code = m.rs("code", "course");

//출력
p.setLayout(code);
p.setBody("");
p.display();

%>