<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId != 0) { m.redirect("../main/index.jsp"); return; }

//객체
WebpageDao webpage = new WebpageDao();

//SSO
if(siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"))) {
	String url = siteinfo.s("sso_url") + ( siteinfo.s("sso_url").indexOf("?") > -1 ?  "&mode=join" : "?mode=join");
	m.redirect(url);
	return;
}

//제한
if(0 > siteinfo.i("join_status")) {
	m.jsAlert(_message.get("alert.member.stop_join"));
	m.jsReplace("/");
	return;
}

//변수
boolean isAuth = (siteinfo.b("auth_yn") || siteinfo.b("ipin_yn"));
String authMethod = (!siteinfo.b("auth_yn") ? "ipin" : "mobile");
String marketingYn = SiteConfig.s("agreement_marketing_yn");

//폼체크
f.addElement("agree_yn1", null, "hname:'이용약관', required:'Y'");
f.addElement("agree_yn2", null, "hname:'개인정보 수집 및 이용', required:'Y'");
if(isAuth) f.addElement("auth_method", authMethod, "hname:'본인인증 수단', required:'Y'");

//세션
if(!"oauth".equals(m.rs("mode"))) {
	mSession.put("join_method", "normal");
	mSession.put("join_vendor", "");
	mSession.put("join_vendor_nm", "");
	mSession.save();
}

//동의
if(m.isPost() && f.validate()) {
	//제한
//	if(isAuth) { m.jsAlert(_message.get("alert.common.abnormal_access")); return; }


	m.delCookie("market_yn");
	m.delCookie("email_yn");
	m.delCookie("sms_yn");
	if("Y".equals(marketingYn)) {
		m.setCookie("market_yn", f.get("market_yn"), 3600);
		m.setCookie("email_yn", f.get("email_yn"), 3600);
		m.setCookie("sms_yn", f.get("sms_yn"), 3600);
//		String cookie = SimpleAES.encrypt((f.get("market_yn") + ":" + f.get("email_yn") + ":" + f.get("sms_yn") + "_AGREE"));
//		response.addHeader("Set-Cookie",
//			"MARKETING=" + cookie + ";"
//			+ "SameSite=none;"
//			+ "Secure;"
//			+ "HttpOnly;"
//			+ "Max-Age=3600;"
//		);
	}

	//이동
	String key = m.getUniqId();
	String ek = m.encrypt(key + "_AGREE");

	m.jsReplace("../member/join.jsp?ek=" + ek + "&k=" + key, "parent");
	return;
}

//타사아이디연동정보
String[] oauths = !"".equals(siteinfo.s("oauth_vendor")) ? m.split("|", siteinfo.s("oauth_vendor")) : new String[0];
DataSet olist = m.arr2loop(oauths);
while(olist.next()) {
	olist.put("vendor_nm", m.getValue(olist.s("name"), Site.oauthVendorsMsg));
	olist.put("en_name", olist.s("name").substring(0, 1).toUpperCase() + olist.s("name").substring(1));
}

//출력
p.setLayout(!isGoMobile ? ch : "mobile");
p.setBody((!isGoMobile ? "member" : "mobile") + ".agreement");
p.setVar("p_title", "회원가입");
p.setVar("form_script", f.getScript());

p.setVar("is_auth", isAuth);
p.setVar("auth_method", authMethod);

p.setLoop("oauth_list", olist);

p.setVar("clause", webpage.getOne("SELECT content FROM " + webpage.table + " WHERE code = 'clause' AND site_id = " + siteId + " AND status = 1"));
p.setVar("oauth_block", 0 < olist.size());
p.setVar("is_oauth", "oauth".equals(m.rs("mode")) && "oauth".equals(mSession.s("join_method")));
p.setVar("oauth_vendor", mSession.s("join_vendor"));
p.setVar("oauth_vendor_nm", mSession.s("join_vendor_nm"));

p.setVar("marketing_yn", "Y".equals(marketingYn));

p.display();

%>