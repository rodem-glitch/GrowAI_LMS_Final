<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId != 0) { m.redirect("../main/index.jsp"); return; }

//SSO
if(siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"))) {
	String url = siteinfo.s("sso_url") + ( siteinfo.s("sso_url").indexOf("?") > -1 ?  "&mode=find" : "?mode=find");
	m.redirect(url);
	return;
}

//객체
UserSleepDao userSleep = new UserSleepDao();
MailDao mail = new MailDao();
MailUserDao mailUser = new MailUserDao();
SmsDao sms = new SmsDao(siteId);
if(siteinfo.b("sms_yn")) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

//변수
String now = m.time("yyyyMMddHHmmss");

//처리
if(m.isPost()) {
	String lid = f.get("login_id");
	String name = f.get("user_nm");
	String email = f.get("email1") + "@" + f.get("email2");
	String mobile = f.get("mobile1") + "-" + f.get("mobile2") + "-" + f.get("mobile3");

	if("email_authno".equals(m.rs("mode"))) {

		//정보
		//userSleep.d(out);
		DataSet uinfo = userSleep.find("user_nm = '" + name + "' AND login_id = '" + lid + "' AND email = '" + email + "' AND site_id = " + siteId + "");
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }

		//메일
		if(mail.isMail(email)) {

			//제한-5분
			int gapLimit = 5;
			int gapMinutes = !"".equals(m.getSession("EMAIL_SENDDATE")) ? m.diffDate("I", m.getSession("EMAIL_SENDDATE"), now) : 999;
			if(gapMinutes < gapLimit) {
				m.jsAlert(_message.get("alert.member.find_remain", new String[] {"gapMinutes=>" + gapMinutes, "remain=>" + (gapLimit - gapMinutes)})); return;
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
		DataSet uinfo = userSleep.find("user_nm = '" + name + "' AND login_Id = '" + lid + "' AND email = '" + email + "' AND site_id = " + siteId + "");
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }

		//인증번호
		if(!authNo.equals(m.getSession("AUTH_NO"))) {
			m.jsAlert(_message.get("alert.member.find.incorrect_authno")); return;
		}

		//갱신
		if(1 > userSleep.awakeUser(uinfo.s("id"))) {
			m.jsAlert(_message.get("alert.member.error_wake"));
			return;
		}

		m.jsAlert(_message.get("alert.member.woken"));
		m.jsReplace("../member/login.jsp", "parent");
		return;

	} else if("sms_authno".equals(m.rs("mode"))) {

		if(!siteinfo.b("sms_yn")) { m.jsAlert(_message.get("alert.sms.noservice")); return; }

		//정보
		DataSet uinfo = userSleep.find("user_nm = '" + name + "' AND login_Id = '" + lid + "' AND mobile = '" + SimpleAES.encrypt(mobile) + "' AND site_id = " + siteId + "");
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }

		//SMS
		if(sms.isMobile(mobile)) {

			//제한-5분
			int gapLimit = 5;
			int gapMinutes = !"".equals(m.getSession("SMS_SENDDATE")) ? m.diffDate("I", m.getSession("SMS_SENDDATE"), now) : 999;
			if(gapMinutes < gapLimit) {
				m.jsAlert(_message.get("alert.member.find_remain", new String[] {"gapMinutes=>" + gapMinutes, "remain=>" + (gapLimit - gapMinutes)})); return;
			}

			//변수
			int authNo = m.getRandInt(123456, 864198);
			String scontent = "[" + siteinfo.s("site_nm") + "] 인증번호 : " + authNo + " / 인증번호가 발급되었습니다.";

			//발송
			sms.send(mobile, siteinfo.s("sms_sender"), scontent, m.time("yyyyMMddHHmm59"));

			//등록
			sms.insertSms(siteId, -9, siteinfo.s("sms_sender"), scontent, uinfo);

			//세션
			m.setSession("SITE_ID", siteId);
			m.setSession("LOGIN_ID", lid);
			m.setSession("MOBILE", mobile);
			m.setSession("USER_NM", name);
			m.setSession("AUTH_NO", authNo);
			m.setSession("SMS_SENDDATE", now);

			m.jsAlert(_message.get("alert.member.find.authno_to_mobile"));
			return;
		} else {
			m.jsAlert(_message.get("alert.member.unvalid_mobile"));
			return;
		}

	} else if("sms_passwd".equals(m.rs("mode"))) {

		if(!siteinfo.b("sms_yn")) { m.jsAlert(_message.get("alert.sms.noservice")); return; }

		String authNo = f.get("auth_no");

		if(!(""+siteId).equals(m.getSession("SITE_ID"))
			|| !lid.equals(m.getSession("LOGIN_ID"))
			|| !mobile.equals(m.getSession("MOBILE"))
			|| !name.equals(m.getSession("USER_NM"))
		) {
			m.jsAlert(_message.get("alert.common.abnormal_access")); return;
		}

		//정보
		DataSet uinfo = userSleep.find("user_nm = '" + name + "' AND login_Id = '" + lid + "' AND mobile = '" + SimpleAES.encrypt(mobile) + "' AND site_id = " + siteId + "");
		if(!uinfo.next()) { m.jsAlert(_message.get("alert.member.not_accurate"));	return; }

		//인증번호
		if(!authNo.equals(m.getSession("AUTH_NO"))) {
			m.jsAlert(_message.get("alert.member.find.incorrect_authno")); return;
		}

		//갱신
		if(1 > userSleep.awakeUser(uinfo.s("id"))) {
			m.jsAlert(_message.get("alert.member.error_wake"));
			return;
		}

		m.jsAlert(_message.get("alert.member.woken"));
		m.jsReplace("../member/login.jsp", "parent");
		return;
	}
}

//출력
p.setLayout(ch);
p.setBody("member.sleep_awake");
p.setVar("sms_block", siteinfo.b("sms_yn"));
p.display();

%>