<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

m.redirect("question_list.jsp");
/*
//접근권한
if(!Menu.accessible(32, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//출력
p.setBody("question.question");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("cid", m.rs("cid"));
p.display();
*/

%>