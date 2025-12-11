<%@ page contentType="text/html; charset=utf-8" %>
<%@ include file="/init.jsp" %>
<%

KollusDao kollus = new KollusDao(siteinfo.s("access_token"), siteinfo.s("security_key"), "b0289d0aba979b8c0256db3c640ea3fc");

String url = kollus.getPlayUrl("ZxnTiwzk", "1_hopegiver");
out.print("<a href='" + url + "'>" + url + "</a>");


%>