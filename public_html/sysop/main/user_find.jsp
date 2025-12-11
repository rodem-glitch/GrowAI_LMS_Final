<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%


//출력
p.setLayout("pop");
p.setBody("main.user_find");
p.setVar("p_title", "회원 선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.display();

%>