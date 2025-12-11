<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(134, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//이동
if("lgu".equals(siteinfo.s("pg_nm"))) {
	m.redirect("http://pgweb.uplus.co.kr/ms/mertpotal/retrieveMertAdminLoginPage.do");
	return;
} else if("inicis".equals(siteinfo.s("pg_nm"))) {
	m.redirect("https://iniweb.inicis.com");
	return;
} else if("allat".equals(siteinfo.s("pg_nm"))) {
	//m.redirect("https://www.allatpay.com/servlet/AllatBizV2/login/LoginCL");
	m.redirect("https://cp.mcash.co.kr/mcht/login.jsp");
	return;
} else if("kicc".equals(siteinfo.s("pg_nm"))) {
	m.redirect("https://office.easypay.co.kr/index.html");
	return;
} else if("payletter".equals(siteinfo.s("pg_nm"))) {
	m.redirect("https://psp.payletter.com:999/");
	return;
} else {
	m.redirect("http://pgweb.uplus.co.kr/ms/mertpotal/retrieveMertAdminLoginPage.do");
}

%>