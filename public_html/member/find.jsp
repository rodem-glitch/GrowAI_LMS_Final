<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId != 0) { m.redirect("../main/index.jsp"); return; }

//SSO
if(siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"))) {
	String url = siteinfo.s("sso_url") + ( siteinfo.s("sso_url").indexOf("?") > -1 ?  "&mode=find" : "?mode=find");
	m.redirect(url);
	return;
}

//폼입력
int udid = m.ri("udid");

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"ktalk_"});

//객체
UserDao user = new UserDao();
FileDao file = new FileDao();
UserDeptDao userDept = new UserDeptDao();
MailDao mail = new MailDao();
MailUserDao mailUser = new MailUserDao();
SmsDao sms = new SmsDao(siteId);
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
if(siteinfo.b("sms_yn")) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));
KtalkDao ktalk = new KtalkDao(siteId);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId);

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

//변수
String now = m.time("yyyyMMddHHmmss");

//처리
if(m.isPost()) {
	String lid = f.get("login_id");
	String name = f.get("user_nm");
	String email = f.get("email1") + "@" + f.get("email2");
	String mobile = f.get("mobile1") + "-" + f.get("mobile2") + "-" + f.get("mobile3");

	if("find_id".equals(m.rs("mode"))) {
		DataSet uinfo = user.find("user_nm = ? AND email = ? AND site_id = " + siteId + "", new Object[] {name, email}, 1);
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }

		m.jsAlert(_message.get("alert.member.find.id", new String[] {"name=>" + name, "login_id=>" + uinfo.s("login_id")}));
		return;

	} else if("email_authno".equals(m.rs("mode"))) {

		//정보
		DataSet uinfo = user.find("user_nm = ? AND login_id = ? AND email = ? AND site_id = " + siteId + "", new Object[] {name, lid, email}, 1);
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }

		//메일
		if(mail.isMail(email)) {

			//제한-3분
			int gapLimit = 3;
			int gapMinutes = !"".equals(m.getSession("EMAIL_SENDDATE")) ? m.diffDate("I", m.getSession("EMAIL_SENDDATE"), now) : 999;
			if(gapMinutes < gapLimit) {
				m.jsAlert(_message.get("alert.member.find.remain", new String[] {"gapMinutes=>" + gapMinutes, "remain=>" + (gapLimit - gapMinutes)})); return;
			}

			//발송
			int authNo = m.getRandInt(123456, 864198);
			p.setVar("auth_no", authNo + "");
			mail.send(siteinfo, uinfo, "findpw_authno", p);

			//세션
			m.setSession("SITE_ID", siteId);
			m.setSession("LOGIN_ID", lid);
			m.setSession("EMAIL", email);
			m.setSession("USER_NM", name);
			m.setSession("AUTH_NO", authNo);
			m.setSession("EMAIL_SENDDATE", now);

			m.jsAlert(_message.get("alert.member.find.authno_to_email"));
			return;
		} else {
			m.jsAlert(_message.get("alert.member.unvalid_email"));
			return;
		}

	} else if("email_passwd".equals(m.rs("mode"))) {

		String authNo = f.get("auth_no");

		if(!(""+siteId).equals(m.getSession("SITE_ID"))
			|| !lid.equals(m.getSession("LOGIN_ID"))
			|| !email.equals(m.getSession("EMAIL"))
			|| !name.equals(m.getSession("USER_NM"))
		) {
			m.jsAlert(_message.get("alert.common.abnormal_access")); return;
		}

		//정보
		DataSet uinfo = user.find("user_nm = ? AND login_id = ? AND email = ? AND site_id = " + siteId + "", new Object[] {name, lid, email}, 1);
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }

		//인증번호
		if(!authNo.equals(m.getSession("AUTH_NO"))) {
			m.jsAlert(_message.get("alert.member.find.incorrect_authno")); return;
		}

		//메일
		if(mail.isMail(email)) {

			String newPasswd = m.getUniqId();

			//갱신
			if(-1 == user.execute("UPDATE " + user.table + " SET passwd = '" + m.encrypt(newPasswd,"SHA-256") + "', fail_cnt = 0, passwd_date = '' WHERE id = " + uinfo.i("id") + "")) {
				m.jsAlert(_message.get("alert.common.error_modify")); return;
			}

			//발송
			p.setVar("new_passwd", newPasswd);
			mail.send(siteinfo, uinfo, "findpw_newpw", p);

			//세션
			m.setSession("SITE_ID", "");
			m.setSession("LOGIN_ID", "");
			m.setSession("EMAIL", "");
			m.setSession("USER_NM", "");
			m.setSession("AUTH_NO", "");

			m.jsAlert(_message.get("alert.member.find.info_to_email"));
			m.jsReplace((isSSL ? "http://" + f.get("domain") : "") + "/member/login.jsp", "parent");
			return;
		} else {
			m.jsAlert(_message.get("alert.member.unvalid_email"));
			return;
		}

	} else if("sms_authno".equals(m.rs("mode"))) {

		if(!siteinfo.b("sms_yn")) { m.jsAlert(_message.get("alert.sms.noservice")); return; }

		String target = m.rs("target");
		//boolean passwordBlock = "password".equals(target);
		boolean passwordBlock = !"id".equals(target);

		//정보
		DataSet uinfo =
			passwordBlock ? user.find("user_nm = ? AND login_id = ? AND mobile = ? AND site_id = " + siteId + "", new Object[] {name, lid, mobile}, 1)
			: user.find("user_nm = ? AND mobile = ? AND site_id = " + siteId + "", new Object[] {name, mobile}, 1);
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate")); return; }
		if(passwordBlock && !lid.equals(uinfo.s("login_id"))) { m.jsAlert(_message.get("alert.member.not_accurate")); return; }

		//SMS
		if(sms.isMobile(mobile)) {

			//제한-3분
			int gapLimit = 3;
			int gapMinutes = !"".equals(m.getSession("SMS_SENDDATE_" + target)) ? m.diffDate("I", m.getSession("SMS_SENDDATE_" + target), now) : 999;
			if(gapMinutes < gapLimit) {
				m.jsAlert(_message.get("alert.member.find.remain", new String[] {"gapMinutes=>" + gapMinutes, "remain=>" + (gapLimit - gapMinutes)})); return;
			}

			//변수
			int authNo = m.getRandInt(123456, 864198);
			
			p.setVar("auth_no", authNo);
			if("Y".equals(siteconfig.s("ktalk_yn"))) {
				ktalkTemplate.sendKtalk(siteinfo, uinfo, "findpw_authno", p);
			} else {
				smsTemplate.sendSms(siteinfo, uinfo, "findpw_authno", p);
			}

			//세션
			m.setSession("SITE_ID", siteId);
			m.setSession("LOGIN_ID", lid);
			m.setSession("MOBILE", mobile);
			m.setSession("USER_NM", name);
			m.setSession("AUTH_NO_" + target, authNo);
			m.setSession("SMS_SENDDATE_" + target, now);

			m.jsAlert(_message.get("alert.member.find.authno_to_mobile"));
			return;
		} else {
			m.jsAlert(_message.get("alert.member.unvalid_mobile"));
			return;
		}

	} else if("sms_passwd".equals(m.rs("mode"))) {

		if(!siteinfo.b("sms_yn")) { m.jsAlert(_message.get("alert.sms.noservice")); return; }

		String authNo = f.get("auth_no");
		String target = m.rs("target");
		//boolean passwordBlock = "password".equals(target);
		boolean passwordBlock = !"id".equals(target);

		if(!(""+siteId).equals(m.getSession("SITE_ID"))
			|| (passwordBlock && !lid.equals(m.getSession("LOGIN_ID")))
			|| !mobile.equals(m.getSession("MOBILE"))
			|| !name.equals(m.getSession("USER_NM"))
		) {
			m.jsAlert(_message.get("alert.common.abnormal_access")); return;
		}

		//정보
		DataSet uinfo = 
			passwordBlock ? user.find("user_nm = ? AND login_id = ? AND mobile = ? AND site_id = " + siteId + "", new Object[] {name, lid, mobile}, 1)
			: user.find("user_nm = ? AND mobile = ? AND site_id = " + siteId + "", new Object[] {name, mobile}, 1);
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }
		if(passwordBlock && !lid.equals(uinfo.s("login_id"))) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }

		//인증번호
		if(!authNo.equals(m.getSession("AUTH_NO_" + target))) {
			m.jsAlert(_message.get("alert.member.find.incorrect_authno")); return;
		}

		//SMS
		if(sms.isMobile(mobile)) {

			String newPasswd = m.getUniqId(8);

			//갱신
			if(passwordBlock && -1 == user.execute("UPDATE " + user.table + " SET passwd = '" + m.encrypt(newPasswd,"SHA-256") + "', fail_cnt = 0 WHERE id = " + uinfo.i("id") + "")) {
				m.jsAlert(_message.get("alert.common.error_modify")); return;
			}

			p.setVar("login_id", uinfo.s("login_id"));
			p.setVar("new_passwd", newPasswd);
			if("Y".equals(siteconfig.s("ktalk_yn"))) {
				ktalkTemplate.sendKtalk(siteinfo, uinfo, passwordBlock ? "findpw_newpw" : "findid", p);
			} else {
				smsTemplate.sendSms(siteinfo, uinfo, passwordBlock ? "findpw_newpw" : "findid", p);
			}

			m.setSession("SITE_ID", "");
			m.setSession("LOGIN_ID", "");
			m.setSession("MOBILE", "");
			m.setSession("USER_NM", "");
			m.setSession("AUTH_NO_" + target, "");

			m.jsAlert(_message.get("alert.member.find.info_to_mobile"));
			m.jsReplace("../member/login.jsp", "parent");
			return;
		} else {
			m.jsAlert(_message.get("alert.member.unvalid_mobile"));
			return;
		}
	}

}

//출력
p.setLayout(ch);
p.setBody("member.find");
p.setVar("p_title", "비밀번호찾기");
p.setVar("query", m.qs());

p.setVar("sms_block", siteinfo.b("sms_yn"));
p.setVar("close_block", siteinfo.b("close_yn") || isB2B);
p.setVar("domain", request.getServerName());

p.setVar("is_b2b", isB2B);
p.setVar("b2binfo", B2Binfo);
p.display();

%>