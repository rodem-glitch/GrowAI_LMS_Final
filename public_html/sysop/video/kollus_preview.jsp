<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String key = m.rs("key");
if("".equals(key)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
KollusDao kollus = new KollusDao(siteId);
String url = kollus.getPlayUrl(key, "");
if("https".equals(request.getScheme())) url = url.replace("http://", "https://");

m.redirect(url);

%>