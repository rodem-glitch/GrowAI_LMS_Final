<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId != 0) {
	if(!userB2BBlock) m.redirect("../mobile/index.jsp");
	else m.redirect("../mobile/mypage.jsp");
	return;
}

//폼입력
String returl = m.rs("returl");

//SSO
if(siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"))) {
	m.setSession("RETURL", returl);
	m.redirect(siteinfo.s("sso_url") + (!"".equals(returl) ? "?returl=" + m.urlencode(returl) : ""));
	return;
}
returl = !"".equals(returl) ? returl : "/mobile/mypage.jsp";
if((-1 < returl.indexOf("http://") || -1 < returl.indexOf("https://")) && 0 > returl.indexOf(siteinfo.s("domain"))) returl = "/mobile/mypage.jsp";
//if(!"".equals(mSession.s("b2b_domain"))) returl = "/mobile/mypage.jsp";

//폼입력
String id = m.rs("id");
String passwd = m.rs("passwd");
String accessToken = m.rs("access_token");
String ek = m.rs("ek");
int udid = m.ri("udid");

//객체
UserDao user = new UserDao();
FileDao file = new FileDao();
GroupDao group = new GroupDao();
UserDeptDao userDept = new UserDeptDao();
UserLoginDao userLogin = new UserLoginDao();

//폼체크
f.addElement("id", null, "hname:'아이디', required:'Y'");
f.addElement("passwd", null, "hname:'비밀번호', required:'Y'");
f.addElement("udid", null, "hname:'부서아이디'");

//정보-B2B
boolean isB2B = false;
DataSet B2Binfo = new DataSet();
if(0 < udid) {
	B2Binfo = userDept.query(
		" SELECT a.id, a.b2b_nm, f.filename b2b_file "
		+ " FROM " + userDept.table + " a " 
		+ " LEFT JOIN " + file.table + " f ON f.module = 'dept' AND f.module_id = a.id AND f.status = 1 "
		+ " WHERE a.id = ? AND a.site_id = ? AND a.status = 1 "
		, new Integer[] {udid, siteId}
	);
	if(B2Binfo.next()) {
		isB2B = true;
		B2Binfo.put("b2b_file_url", m.getUploadUrl(B2Binfo.s("b2b_file")));
	}
}

//SSL인증처리
boolean isToken = !"".equals(accessToken) && ek.equals(m.encrypt(accessToken + sslDomain + m.time("yyyyMMdd")));

if(m.isPost() || isToken) {
	if(!isToken && !f.validate()) { m.jsAlert(null != f.errMsg && !"".equals(f.errMsg) ? f.errMsg : "올바른 입력이 아닙니다."); return; }

	DataSet info;
	ArrayList<Object> qs = new ArrayList<Object>();
	qs.add(siteId);
	qs.add(siteinfo.i("login_block_cnt"));
	qs.add(siteinfo.i("login_block_cnt"));
	if(0 < udid) qs.add(udid);

	if(isToken) {
		qs.add(accessToken);
		info = user.find(
			" site_id = ? AND (0 = ? OR fail_cnt < ?) "
			+ (0 < udid ? " AND dept_id = ? " : "")
			+ " AND access_token = ? AND status IN (1, 0, 30, 31) "
			, qs.toArray(), 1
		);
		
		//세션-SSL
		if("".equals(mSession.s("login_method"))) {
			mSession.put("login_method", "direct");
			mSession.save();
		}
	} else {
		qs.add(id);
		if(64 > passwd.length()) passwd = m.encrypt(passwd, "SHA-256");
		info = user.find(
			" site_id = ? AND (0 = ? OR fail_cnt < ?) "
			+ (0 < udid ? " AND dept_id = ? " : "")
			+ " AND login_id = ? AND status IN (1, 0, 30, 31) "
			, qs.toArray(), 1
		);

		//세션-SSL
		mSession.put("login_method", "direct");
		mSession.save();
	}

	if(info.next()) {
		if(!isToken && !passwd.equals(info.s("passwd"))) {
			//제한-비밀번호오류
			user.item("fail_cnt", info.i("fail_cnt") + 1);
			if(!user.update("id = " + info.i("id") + " AND site_id = " + siteId)) { }

			m.jsAlert(
				_message.get("alert.member.reenter_info")
				+ (0 < siteinfo.i("login_block_cnt") ? _message.get("alert.member.rule_fail", new String[] {"login_block_cnt=>" + siteinfo.i("login_block_cnt")}) : "")
			); //아이디/비밀번호를 확인하세요. - 비밀번호 오류
			if(!isSSL) m.js("parent.resetPassword();");
			return;

		} else if(0 == info.i("status")) {
			if(0 == siteinfo.i("join_status")) m.jsError(_message.get("alert.member.wait_approve")); //승인대기중인 아이디입니다.
			else m.jsError(_message.get("alert.member.nodata")); //회원 정보가 없습니다.
			return;

		} else {

			//변수
			String replaceUrl = "";

			//휴면회원인 경우
			if(31 == info.i("status")) {
				m.jsAlert(_message.get("alert.member.wake") + _message.get("alert.member.login_pc")); //휴면회원으로 전환되어 본인인증 후 서비스를 이용하실 수 있습니다. PC이용안내문구
				return;

			//개인정보활용에 동의하지 않은 경우
			} else if(!"Y".equals(info.s("privacy_yn")) && "Y".equals(siteinfo.s("sso_privacy_yn"))) {
				ek = m.encrypt("PRIVACY_" + info.s("id") + "_AGREE_" + m.time("yyyyMMdd"));
				replaceUrl = "/mobile/privacy_agree.jsp?id=" + info.s("id") + "&ek=" + ek;

			//정상회원인 경우
			} else {
				if(!isSSL) {
					UserSession.setUserId(info.i("id"));
					UserSession.setSession(mSession.s("id"));

					String tmpGroups = group.getUserGroup(info);
					auth.put("ID", info.s("id"));
					auth.put("LOGINID", info.s("login_id"));
					auth.put("LOGINMETHOD", (!"".equals(mSession.s("login_method")) ? mSession.s("login_method") : "direct"));
					auth.put("KIND", info.s("user_kind"));
					auth.put("NAME", info.s("user_nm"));
					auth.put("EMAIL", info.s("email"));
					auth.put("DEPT", info.i("dept_id"));
					auth.put("SESSIONID", mSession.s("id"));
					auth.put("GROUPS", tmpGroups);
					auth.put("GROUPS_DISC", group.getMaxDiscRatio());
					auth.put("B2BNAME", B2Binfo.s("b2b_nm"));
					auth.put("B2BFILE", B2Binfo.s("b2b_file_url"));
					auth.put("TUTOR_YN", "Y".equals(info.s("tutor_yn")) ? "Y" : "N");
					//auth.put("ALOGIN_YN", "N");
					auth.setAuthInfo();

					user.item("fail_cnt", 0);
					user.item("conn_date", m.time("yyyyMMddHHmmss"));
					user.item("access_token", "");
					if(30 == info.i("status")) user.item("status", 1);
					if(!user.update("id = " + info.i("id"))) {
						m.jsAlert(_message.get("alert.member.error_login")); //로그인하는 중 오류가 발생했습니다.
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

				} else {
					accessToken = m.md5(m.getUniqId());
					ek = m.encrypt(accessToken + sslDomain + m.time("yyyyMMdd"));
					user.item("access_token", accessToken);
					user.update("id = " + info.i("id") + " AND site_id = " + siteId);
					//m.redirect("http://" + f.get("domain") + "/member/login.jsp?access_token=" + accessToken + "&ek=" + ek);
					m.jsReplace("http://" + f.get("domain") + "/mobile/login.jsp?returl=" + m.urlencode(returl) + "&access_token=" + accessToken + "&ek=" + ek + (0 < udid ? "&udid=" + udid : ""));
					return;
				}

			}

			//이동
			if("".equals(replaceUrl)) replaceUrl = returl;
			else replaceUrl = (siteinfo.b("ssl_yn") ? "https://" : "http://") + siteinfo.s("domain") + replaceUrl;
			m.jsReplace(replaceUrl, "parent");
			return;
		}
	}

	if(isToken) {		
		if(0 == siteinfo.i("join_status")) m.jsError(_message.get("alert.member.wait_approve")); //승인대기중인 아이디입니다.
		else m.jsError(_message.get("alert.member.nodata")); //회원 정보가 없습니다.
	} else {
		m.jsAlert(
			_message.get("alert.member.reenter_info")
			+ (0 < siteinfo.i("login_block_cnt") ? _message.get("alert.member.rule_fail", new String[] {"login_block_cnt=>" + siteinfo.i("login_block_cnt")}) : "")
		); //아이디/비밀번호를 확인하세요. - 정보없음
	}
	if(!isSSL) m.js("parent.resetPassword();");
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
p.setLayout(ch);
p.setBody("mobile.login");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
p.setVar("is_login_page", true);

p.setLoop("oauth_list", olist);

p.setVar("returl_conv", m.urlencode(returl));
p.setVar("auth_block", siteinfo.b("auth_login_yn"));
p.setVar("oauth_block", 0 < olist.size());
p.setVar("close_block", siteinfo.b("close_yn") || isB2B);
p.setVar("domain", request.getServerName());

p.setVar("is_b2b", isB2B);
p.setVar("b2binfo", B2Binfo);
if(isB2B) {
	p.setVar("SYS_B2BBLOCK", true);
	p.setVar("SYS_B2BNAME", B2Binfo.s("b2b_nm"));
	p.setVar("SYS_B2BFILE", B2Binfo.s("b2b_file_url"));
}
p.display();

%>