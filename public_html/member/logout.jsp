<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

String auth2Type = m.rs("auth2_type", siteinfo.s("auth2_type"));

m.setSession("OTP_KEY", "");
m.setSession("BARCODE_URL", "");
m.setSession(auth2Type + "_SENDDATE_OTP", "");
m.setSession("EO_SENDDATE_OTP", "");
mSession.delSession();
auth.delAuthInfo();

UserDeptDao userDept = new UserDeptDao();
UserLoginDao userLogin = new UserLoginDao();

userLogin.item("id", userLogin.getSequence());
userLogin.item("site_id", siteId);
userLogin.item("user_id", userId);
userLogin.item("admin_yn", "N");
userLogin.item("login_type", ("session".equals(m.rs("mode")) ? "S" : "O"));
userLogin.item("ip_addr", userIp);
userLogin.item("agent", request.getHeader("user-agent"));
userLogin.item("device", userLogin.getDeviceType(request.getHeader("user-agent")));
userLogin.item("log_date", m.time("yyyyMMdd"));
userLogin.item("reg_date", m.time("yyyyMMddHHmmss"));
if(!userLogin.insert()) {}

if(siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"))) {
	//SSO
	String url = siteinfo.s("sso_url") + ( siteinfo.s("sso_url").indexOf("?") > -1 ?  "&mode=logout" : "?mode=logout");
	m.redirect(url);
} else if(!"".equals(userB2BName) && null != userB2BName) {
	//B2B
	String url = userDept.getB2BDomain(userDeptId);
	if(!"".equals(url)) m.redirect("http://" + url + "." + SiteConfig.s("join_b2b_domain"));
	else m.redirect("../main/index.jsp");
} else {
	m.redirect("../main/index.jsp");
}

%>