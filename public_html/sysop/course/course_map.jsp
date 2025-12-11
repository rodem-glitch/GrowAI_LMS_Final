<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }


//출력
p.setLayout("pop");
p.setBody("course.course_map");
p.setVar("p_title", "교육장소");
p.setVar("address", m.rs("a"));
p.display();

%>