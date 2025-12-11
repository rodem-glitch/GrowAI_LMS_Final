<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String key = m.rs("key");
if("".equals(key)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
KollusDao kollus = new KollusDao(siteId);
String url = kollus.getPlayUrl(key, "" + siteId + "_sysop" + loginId);


System.out.println("url=====>"+url);

//m.redirect(url + "&uservalue0=" + (-1 * userId) + "&uservalue1=-99&uservalue2=-99&uservalue3=" + m.encrypt(siteId + sysToday + userId, "SHA-256"));

%>