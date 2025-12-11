<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%@ page import="java.util.HashMap" %><%@ page import="malgnsoft.json.*" %><%

//기본키
String code = m.rs("code");
String state = m.rs("state");

//변수
DataSet siteconfig = SiteConfig.getArr(new String[] {"new_"});
boolean isNewVersion = "Y".equals(siteconfig.s("new_kakao_yn"));

//폼입력
String error = m.rs("error");
String errorDescription = m.rs("error_description");
String returl = m.rs("returl");

//객체
UserDao user = new UserDao();

//정보
DataSet oklist = new DataSet();
try {
	oklist = Json.decode(siteinfo.s("oauth_key"));
}
catch(JSONException jsone) {
	m.errorLog("JSONException : " + jsone.getMessage(), jsone);
	oklist.addRow();
}
catch(Exception e) {
	m.errorLog("Exception : " + e.getMessage(), e);
	oklist.addRow();
}
if(!oklist.next()) { m.jsAlert(_message.get("alert.member.nodata_oauth")); m.js("parent.CloseLayer();"); return; }

if(isNewVersion) {
	//객체
	SnsLogin sns = new SnsLogin(request, session);
	//sns.setDebug(out);
	sns.setClient("kakao", oklist.s("kakao_id"), oklist.s("kakao_secret"));

	//제한-사용자취소및오류
	if("access_denied".equals(error)) {
		m.js("window.close();");
		return;
	} else if(!"".equals(error)) {
		m.jsErrClose(error + " - " + errorDescription);
		return;
	}

	//처리
	if(!"".equals(code) && !"".equals(state)) {
		//변수
		HashMap oauthMap = sns.getProfile(m.rs("code"));
		if(oauthMap == null || !oauthMap.containsKey("kakao_account")) {
			m.jsAlert(_message.get("alert.member.nodata_login") + " [1]");
			m.js("//window.close();");
			return;
		}
		HashMap accountMap = (HashMap) oauthMap.get("kakao_account");
		HashMap propMap = oauthMap.containsKey("properties") ? (HashMap) oauthMap.get("properties") : new HashMap<String, String>();
		HashMap profileMap = accountMap.containsKey("profile") ? (HashMap) accountMap.get("profile") : new HashMap<String, String>();

		String propNickname = propMap.containsKey("nickname") ? propMap.get("nickname").toString() : "";
		String profileNickname = profileMap.containsKey("nickname") ? profileMap.get("nickname").toString() : "";

		//필수정보미비
		if(!accountMap.containsKey("email") || ("".equals(propNickname) && "".equals(profileNickname))) {
			p.setLayout("blank");
			p.setBody("member.login_reauth");
			p.setVar("kakao_block", true);
			p.setVar("reauth_url", sns.getAuthUrl("kakao"));
			//p.setVar("reauth_url", sns.getAuthUrl("kakao") + "&auth_type=rerequest");
			p.display();
			return;
		}

		oauthMap.put("id", oauthMap.get("id").toString());
		oauthMap.put("name", !"".equals(profileNickname) ? profileNickname : profileNickname);
		oauthMap.put("email", accountMap.get("email").toString());

		//정보
		DataSet info = user.find("login_id = 'kakao_" + oauthMap.get("id").toString() + "' AND site_id = " + siteId + "");
		if(info.next()) {
			//세션
			mSession.put("login_method", "oauth-kakao");
			mSession.save();

			//로그인
			String accessToken = m.md5(m.getUniqId());
			String ek = m.encrypt(accessToken + sslDomain + m.time("yyyyMMdd"));
			user.item("access_token", accessToken);
			if(!user.update("id = " + info.i("id") + " AND site_id = " + siteId)) {
				m.jsErrClose(_message.get("alert.member.error_find"));
				return;
			}
			m.jsReplace("../" + (!m.isMobile() ? "member" : "mobile") + "/login.jsp?returl=" + returl + "&access_token=" + accessToken + "&ek=" + ek, "opener");
			m.js("window.close();");
			return;
		}

		//세션
		mSession.put("join_method", "oauth");
		mSession.put("join_vendor", "kakao");
		mSession.put("join_vendor_nm", "카카오");
		mSession.put("join_data", Json.encode(oauthMap));
		mSession.save();

		//이동
		m.jsReplace("../member/agreement.jsp?mode=oauth", "opener");
		m.js("window.close();");

	} else {
		m.redirect(sns.getAuthUrl("kakao"));
	}
} else {
	//객체
	OAuthClient oauth = new OAuthClient(request, session);
	//oauth.setDebug(out);
	oauth.setClient("kakao", oklist.s("kakao_id"), oklist.s("kakao_secret"));

	//제한-사용자취소및오류
	if("access_denied".equals(error)) {
		m.js("window.close();");
		return;
	} else if(!"".equals(error)) {
		m.jsErrClose(error + " - " + errorDescription);
		return;
	}

	//처리
	if(!"".equals(code) && !"".equals(state)) {

		//변수
		HashMap oauthMap = oauth.getProfile(m.rs("code"));
		if(oauthMap == null || !oauthMap.containsKey("kakao_account")) {
			m.jsAlert(_message.get("alert.member.nodata_login") + " [1]");
			m.js("//window.close();");
			return;
		}
		HashMap accountMap = (HashMap) oauthMap.get("kakao_account");
		HashMap propMap = oauthMap.containsKey("properties") ? (HashMap) oauthMap.get("properties") : new HashMap<String, String>();
		HashMap profileMap = accountMap.containsKey("profile") ? (HashMap) accountMap.get("profile") : new HashMap<String, String>();

		String propNickname = propMap.containsKey("nickname") ? propMap.get("nickname").toString() : "";
		String profileNickname = profileMap.containsKey("nickname") ? profileMap.get("nickname").toString() : "";

		//필수정보미비
		if(!accountMap.containsKey("email") || ("".equals(propNickname) && "".equals(profileNickname))) {
			p.setLayout("blank");
			p.setBody("member.login_reauth");
			p.setVar("kakao_block", true);
			p.setVar("reauth_url", oauth.getAuthUrl("kakao"));
			//p.setVar("reauth_url", oauth.getAuthUrl("kakao") + "&auth_type=rerequest");
			p.display();
			return;
		}

		oauthMap.put("id", oauthMap.get("id").toString());
		oauthMap.put("name", !"".equals(profileNickname) ? profileNickname : profileNickname);
		oauthMap.put("email", accountMap.get("email").toString());

		//정보
		DataSet info = user.find("login_id = 'kakao_" + oauthMap.get("id").toString() + "' AND site_id = " + siteId + "");
		if(info.next()) {
			//세션
			mSession.put("login_method", "oauth-kakao");
			mSession.save();

			//로그인
			String accessToken = m.md5(m.getUniqId());
			String ek = m.encrypt(accessToken + sslDomain + m.time("yyyyMMdd"));
			user.item("access_token", accessToken);
			if(!user.update("id = " + info.i("id") + " AND site_id = " + siteId)) {
				m.jsErrClose(_message.get("alert.member.error_find"));
				return;
			}
			m.jsReplace("../" + (!isGoMobile ? "member" : "mobile") + "/login.jsp?returl=" + returl + "&access_token=" + accessToken + "&ek=" + ek, "opener");
			m.js("window.close();");
			return;
		}

		//세션
		mSession.put("join_method", "oauth");
		mSession.put("join_vendor", "kakao");
		mSession.put("join_vendor_nm", "카카오");
		mSession.put("join_data", Json.encode(oauthMap));
		mSession.save();

		//이동
		m.jsReplace("../member/agreement.jsp?mode=oauth", "opener");
		m.js("window.close();");

	} else {
		m.redirect(oauth.getAuthUrl("kakao"));
	}
}

%>