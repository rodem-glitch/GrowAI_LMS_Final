<%@ include file="/init.jsp" %><%

String ch = "member";

String sslDomain = request.getServerName().indexOf(".malgn.co.kr") > 0 ? "ssl.malgn.co.kr" : "ssl.malgnlms.com";
boolean isSSL = "https".equals(request.getScheme()) && sslDomain.equals(request.getServerName()) && !"".equals(f.get("domain"));

if(siteinfo.b("ssl_yn")) {
	sslDomain = siteinfo.s("domain");
	isSSL = false;
}

//if("edu.kuca.kr".equals(f.get("domain"))) m.js("try { console.log(\"a - " + isSSL + " / " + siteinfo.i("id") + " / " + siteinfo.s("domain") + "\"); } catch {}");
if(isSSL) {
	//Site.remove(f.get("domain"));
	siteinfo = Site.getSiteInfo(f.get("domain"));
	if("".equals(siteinfo.s("doc_root"))) { m.jsError(_message.get("alert.site.nodata")); return; }
	siteId = siteinfo.i("id");
	
	SiteConfig = new SiteConfigDao(siteinfo.i("id"));

	mSession.put("id", f.get("session_id"));
}
p.setVar("SSL_DOMAIN", sslDomain);

%>