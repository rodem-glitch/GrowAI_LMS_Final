<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String key = m.rs("key");
if("".equals(key)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
KollusDao kollus = new KollusDao(siteId);

//변수
String url = kollus.getLiveUrl(key, "" + siteId + "_" + loginId) + "&custom_key=" + SiteConfig.s("kollus_live_custom_key");
if("https".equals(request.getScheme())) url = url.replace("http://", "https://");

//이동
m.redirect(url);

%>