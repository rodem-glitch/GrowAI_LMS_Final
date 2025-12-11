<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(69, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
if("W".equals(siteinfo.s("ovp_vendor"))) {
	m.redirect("../video/list.jsp");
	return;
} else if("C".equals(siteinfo.s("ovp_vendor"))) {
	m.redirect("../kollus/kollus_list.jsp");
	return;
}

%>