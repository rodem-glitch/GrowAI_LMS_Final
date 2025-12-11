<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.net.InetAddress" %><%@ include file="init.jsp" %><%

out.print(InetAddress.getLocalHost().getHostAddress());

%>