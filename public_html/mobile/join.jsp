<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//PC통합
String qs = m.qs("");
if(!"".equals(qs)) qs = "?" + qs;
response.sendRedirect("/member/join.jsp" + qs);

%>