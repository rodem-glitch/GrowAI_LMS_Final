<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int id = m.ri("id");

UserDao user = new UserDao();
GroupDao group = new GroupDao();
UserLoginDao userLogin = new UserLoginDao();


String ek = m.encrypt("PRIVACY_" + id + "_AGREE_" + m.time("yyyyMMdd"));
if(!ek.equals(m.rs("ek"))) {
	m.jsError(_message.get("alert.common.abnormal_access"));
	return;
}

DataSet info = user.find("id = " + id + " AND site_id = " + siteId + " AND status = 1");
if(!info.next()) {
	m.jsError(_message.get("alert.member.nodata"));
	return;
}

//SSO
if(!siteinfo.b("sso_privacy_yn") || info.b("privacy_yn")) {
	m.redirect("/mobile/index.jsp");
	return;
}

//폼체크
f.addElement("agree_yn1", null, "hname:'이용약관'");
f.addElement("agree_yn2", null, "hname:'개인정보 수집 및 이용에 대한 안내', required:'Y'");

//동의
if(m.isPost() && f.validate()) {

	//이동
	user.item("privacy_yn", "Y");
	if(user.update("id = " + id + " AND site_id = " + siteId + " AND status = 1")) {

		UserSession.setUserId(info.i("id"));
		UserSession.setSession(mSession.s("id"));
		
		String tmpGroups = group.getUserGroup(info);

		auth.put("ID", info.s("id"));
		auth.put("LOGINID", info.s("login_id"));
		auth.put("KIND", info.s("user_kind"));
		auth.put("NAME", info.s("user_nm"));
		auth.put("DEPT", info.i("dept_id"));
		auth.put("SESSIONID", mSession.s("id"));
		auth.put("GROUPS", tmpGroups);
		auth.put("GROUPS_DISC", group.getMaxDiscRatio());
		//auth.put("ALOGIN_YN", "N");
		auth.setAuthInfo();

		user.item("conn_date", m.time("yyyyMMddHHmmss"));
		if(30 == info.i("status")) user.item("status", 1);
		if(!user.update("id = " + info.i("id"))) {
			m.jsAlert(_message.get("alert.member.error_login"));
			m.js("parent.resetPassword();");
			return;
		}

		//로그
		userLogin.item("id", userLogin.getSequence());
		userLogin.item("site_id", siteId);
		userLogin.item("user_id", info.i("id"));
		userLogin.item("admin_yn", "N");
		userLogin.item("login_type", "I");
		userLogin.item("ip_addr", userIp);
		userLogin.item("agent", request.getHeader("user-agent"));
		userLogin.item("device", userLogin.getDeviceType(request.getHeader("user-agent")));
		userLogin.item("log_date", m.time("yyyyMMdd"));
		userLogin.item("reg_date", m.time("yyyyMMddHHmmss"));
		if(!userLogin.insert()) { }
	}

	m.jsReplace("/mobile/mypage.jsp", "parent");
	return;
}

//출력
p.setLayout(ch);
p.setBody("mobile.privacy_agree");
p.setVar("form_script", f.getScript());
p.display();

%>