<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//아이디
String sy = m.rs("sy");
int cid = m.ri("cid");

if("".equals(sy) || 0 == cid) { out.print("-"); return ; }

//객체
CourseDao course = new CourseDao();
CourseStepDao step = new CourseStepDao();

out.print((course.getOneInt("SELECT MAX(step) FROM " + step.table + " WHERE course_id = " + cid + " AND year = " + sy) + 1) + "기");

%>