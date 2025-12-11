<%@ include file="/init.jsp" %><%
//CORS 정책 허용
response.setHeader("Access-Control-Allow-Origin", request.getScheme() + "://v.kr.kollus.com");
response.setHeader("Access-Control-Allow-Credentials", "true");

String ch = "sysop";
%>