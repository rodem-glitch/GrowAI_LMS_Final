<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%


//출력
p.setLayout(null);
p.setBody("main.pop_zipcode");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.display();
%>