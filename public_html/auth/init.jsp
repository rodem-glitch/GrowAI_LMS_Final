<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//변수
boolean authYn = siteinfo.b("auth_yn");
boolean ipinYn = siteinfo.b("ipin_yn");

String authCode = siteinfo.s("auth_code");
String authPasswd = siteinfo.s("auth_passwd");

String ipinCode = siteinfo.s("ipin_code");
String ipinPasswd = siteinfo.s("ipin_passwd");

boolean isAuth = authYn || ipinYn;

//제한
if(!isAuth) {
	m.jsError(_message.get("alert.auth.noservice"));
	return;
}

%>