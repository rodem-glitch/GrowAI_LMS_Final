<%@ include file="/init.jsp" %><%

if(isRespWeb) { m.redirect("/main/index.jsp"); return; }

String ch = "mobile";
auth.loginURL = "/mobile/login.jsp";
//auth.loginURL = request.getScheme() + "://" + siteinfo.s("domain") + "/mobile/login.jsp";

String sslDomain = request.getServerName().indexOf(".malgn.co.kr") > 0 ? "ssl.malgn.co.kr" : "ssl.malgnlms.com";
boolean isSSL = "https".equals(request.getScheme()) && sslDomain.equals(request.getServerName()) && !"".equals(f.get("domain"));

if(siteinfo.b("ssl_yn")) {
	sslDomain = siteinfo.s("domain");
	isSSL = false;
}

if(isSSL) {
	siteinfo = Site.getSiteInfo(f.get("domain"));
	if("".equals(siteinfo.s("doc_root"))) { m.jsError(_message.get("alert.site.nodata")); return; }
	siteId = siteinfo.i("id");
	
	//SiteConfig.remove(siteinfo.s("id"));
	//siteconfig = SiteConfig.getSiteConfig(siteId + "");

	mSession.put("id", f.get("session_id"));
}
p.setVar("SSL_DOMAIN", sslDomain);

%>