<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.regex.Pattern" %><%@ include file="init.jsp" %><%

String key = "7B1F83A608723CEDDFA9AED338FC796C";
String ek = m.rs("ek");
int ut = m.ri("ut");

if("".equals(ek) || 1 > ut) { m.jsReplace("modify_verify.jsp"); return; }
if(!ek.equals(m.encrypt(ut + "|" + loginId + "|" + key, "SHA-256"))) { m.jsError("올바른 접근이 아닙니다."); return; }
if(m.getUnixTime() - ut > 3600) {
	m.jsAlert("입력시간이 만료되었습니다. 다시 진행해주시기 바랍니다.");
	m.jsReplace("modify_verify.jsp");
	return;
}

//SSO
boolean isSSO = siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"));

//객체
MCal mcal = new MCal(); mcal.yearRange = 50;
FileDao file = new FileDao();
UserDeptDao userDept = new UserDeptDao();
AgreementLogDao agreementLog = new AgreementLogDao(p, siteId);
MailDao mail = new MailDao();

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"join_", "modify_", "user_etc_"});

//이동-가입설정사용여부
if("Y".equals(siteconfig.s("join_config_yn")) && !isSSO) {
	m.redirect("modify2.jsp?" + m.qs());
	return;
}

//변수
boolean isAuth = (siteinfo.b("auth_yn") || siteinfo.b("ipin_yn"));

if(!isSSO) {

	String[] uemail = m.split("@", uinfo.s("email"), 2);
	String[] mobile = m.split("-", uinfo.s("mobile_conv"), 3);

	int userFileId = 0;
	if(!"".equals(uinfo.s("user_file"))) {
		userFileId = file.getOneInt("SELECT id FROM " + file.table + " WHERE module = 'user' AND module_id = ? AND site_id = ? ORDER BY id DESC", new Integer[] {userId, siteId});
	}

	//폼체크
	f.addElement("passwd", null, "hname:'비밀번호'");
	f.addElement("passwd2", null, "hname:'비밀번호', match:'passwd'");
	if(!isAuth && "".equals(uinfo.s("user_nm"))) f.addElement("user_nm", uinfo.s("user_nm"), "hname:'성명', required:'Y'");
	if(!isAuth) f.addElement("birthday_year", m.time("yyyy", uinfo.s("birthday")), "hname:'생년월일(년도)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
	if(!isAuth) f.addElement("birthday_month", m.time("MM", uinfo.s("birthday")), "hname:'생년월일(월)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
	if(!isAuth) f.addElement("birthday_day", m.time("dd", uinfo.s("birthday")), "hname:'생년월일(일)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
	f.addElement("dept_id", uinfo.i("dept_id"), "hname:'소속', required:'Y'");
	if(!isAuth) f.addElement("gender", uinfo.s("gender"), "hname:'성별'" + (1 < siteconfig.i("join_gender_status") ? ", required:'Y'" : ""));
	f.addElement("zipcode", uinfo.s("zipcode"), "hname:'우편번호'");
	f.addElement("addr", uinfo.s("addr"), "hname:'구 주소'");
	f.addElement("new_addr", uinfo.s("new_addr"), "hname:'도로명 주소'");
	f.addElement("addr_dtl", uinfo.s("addr_dtl"), "hname:'상세주소'");
	if(!isAuth) f.addElement("mobile1", mobile[0], "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
	if(!isAuth) f.addElement("mobile2", mobile[1], "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
	if(!isAuth) f.addElement("mobile3", mobile[2], "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
	f.addElement("email1", uemail[0], "hname:'이메일', required:'Y'");
	f.addElement("email2", uemail[1], "hname:'이메일', required:'Y'");
	f.addElement("user_file", null, "hname:'사진'");
	f.addElement("user_file_k", userFileId, "hname:'사진'");
	f.addElement("user_file_ek", m.sha256(userFileId + "_userfile_" + userId), "hname:'사진'");
	f.addElement("email_yn", uinfo.s("email_yn"), "hname:'이메일수신동의'");
	f.addElement("sms_yn", uinfo.s("sms_yn"), "hname:'SMS수신동의'");
	f.addElement("etc1", uinfo.s("etc1"), "hname:'기타1'");
	f.addElement("etc2", uinfo.s("etc2"), "hname:'기타2'");
	f.addElement("etc3", uinfo.s("etc3"), "hname:'기타3'");
	f.addElement("etc4", uinfo.s("etc4"), "hname:'기타4'");
	f.addElement("etc5", uinfo.s("etc5"), "hname:'기타5'");

	//처리
	if("EMAIL".equals(m.rs("mode"))) {
		//변수
		String email = f.get("e").toLowerCase();

		//제한
		if(0 < user.findCount("id != " + userId + " AND email = '" + email + "' AND site_id = " + siteId + " AND user_kind = 'U' ")) { m.jsAlert(_message.get("alert.member.used_email")); return; }

		//발송
		int authNo = m.getRandInt(123456, 864198);
		p.setVar("auth_no", authNo + "");
		//mailTemplate.sendMail(siteinfo, email, "findpw_authno", "이메일 인증을 위한 인증번호가 발급되었습니다.", p);
		mail.send(siteinfo, email, "findpw_authno", p);

		//세션
		mSession.put("MODIFY_EMAIL", email);
		mSession.put("MODIFY_AUTHNO", "" + authNo);
		mSession.put("MODIFY_SITEID", "" + siteId);
		mSession.put("MODIFY_EMAIL_VERIFIED", "");
		mSession.put("MODIFY_EMAIL_VERIFYDATE", "");
		mSession.save();

		m.jsAlert(_message.get("alert.member.find.authno_to_email"));
		m.js("try { parent.setVerify(); } catch(e) {}");
		return;
	} else if("VERIFY".equals(m.rs("mode"))) {
		//변수
		String email = f.get("e").toLowerCase();
		String code = f.get("c");

		//제한-이메일
		if(0 < user.findCount("id != " + userId + " AND email = '" + email + "' AND site_id = " + siteId + " AND user_kind = 'U' ")) { m.jsAlert(_message.get("alert.member.used_email")); return; }

		//제한-인증번호
		String authEmail = mSession.s("MODIFY_EMAIL");
		String authNo = mSession.s("MODIFY_AUTHNO");
		int authSiteId = mSession.i("MODIFY_SITEID");

		if(!authEmail.equals(email) || !authNo.equals(code) || siteId != authSiteId) {
			m.jsAlert(_message.get("alert.member.email_fail"));
			return;
		}

		//세션
		mSession.put("MODIFY_EMAIL_VERIFIED", email);
		mSession.put("MODIFY_EMAIL_VERIFYDATE", m.time("yyyyMMdd"));
		mSession.save();

		m.jsAlert(_message.get("alert.member.email_success"));
		m.js(""
			+ " try { "
				+ " parent.setSuccess(); "
				+ " parent.document.forms['form1']['verify_email_yn'].value = 'Y'; "
			+ " } catch(e) {} "
		);
		return;
	}

	//수정
	if(m.isPost() && f.validate()) {
		//변수
		String birthday = f.glue("", "birthday_year, birthday_month, birthday_day");
		String passwd = f.get("passwd");
		String email = f.glue("@", "email1, email2").toLowerCase();
		String emailYn = f.get("email_yn", "N");
		String smsYn = f.get("sms_yn", "N");
		boolean changeEmailYn = !uinfo.s("email_yn").equals(emailYn);
		boolean changeSmsYn = !uinfo.s("sms_yn").equals(smsYn);

		if(!"".equals(passwd)) {
			//제한-비밀번호
			if(!passwd.matches("^(?!.*(\\d)\\1)(?=.*?[A-Za-z])(?=.*?[0-9])(?=.*?[\\W_]).{9,}$")) {
				m.jsAlert(_message.get("alert.member.rule_password"));
				return;
			}

			if(64 > passwd.length()) passwd = m.encrypt(passwd, "SHA-256");
			user.item("passwd", passwd);
			if(!passwd.equals(uinfo.s("passwd"))) user.item("passwd_date", m.addDate("d", siteinfo.i("passwd_day"), m.time("yyyyMMdd"), "yyyyMMdd"));
		}

		//이메일변경
		if(!email.equals(uinfo.s("email"))) {
			if(!"@".equals(email)) {
				if(!mail.isMail(email)) {
					m.jsAlert(_message.get("alert.member.unvalid_email"));
					m.js("parent.resetPassword();");
					return;
				}

				if(0 < user.findCount("id != " + userId + " AND email = '" + email + "' AND site_id = " + siteId + " AND user_kind = 'U' ")) {
					m.jsAlert(_message.get("alert.member.used_email"));
					m.js("parent.resetPassword();");
					return;
				}

				if("Y".equals(siteinfo.s("verify_email_yn"))) {
					if(!email.equals(mSession.s("MODIFY_EMAIL_VERIFIED"))
						|| !m.time("yyyyMMdd").equals(mSession.s("MODIFY_EMAIL_VERIFYDATE"))
						|| !"Y".equals(f.get("verify_email_yn", "N"))) {
						m.jsAlert(_message.get("alert.member.email_expired"));
						m.js("parent.resetPassword();");
						return;
					}
				}
			} else {
				email = "";
			}
		}

		if(!isAuth) {
			user.item("birthday", 8 == birthday.length() ? birthday : "");
			user.item("gender", f.getInt("gender", 1));

			String pattern = "(\\d{3})(\\d{3,4})(\\d{4})";
			String newMobile = "";
			if(!"Y".equals(SiteConfig.s("foreign_yn"))) {
				if(!"".equals(f.get("mobile2")) || !"".equals(f.get("mobile3"))) {
					newMobile = f.get("mobile1") + f.get("mobile2") + f.get("mobile3");
					if(!Pattern.matches(pattern, newMobile)) {
						m.jsAlert(_message.get("alert.member.unvalid_mobile"));
						m.js("parent.resetPassword();");
						return;
					}
					newMobile = newMobile.replaceAll(pattern, "$1-$2-$3");
				}
			} else {
				newMobile = f.get("mobile1");
			}

			user.item("mobile", newMobile);

			//회원명이 없는 경우 수정이 가능
			if("".equals(uinfo.s("user_nm")) && !"".equals(f.get("user_nm"))) {
				user.item("user_nm", f.get("user_nm"));
				auth.put("NAME", f.get("user_nm"));
			}

			auth.put("MOBILE", newMobile);
			auth.put("BIRTHDAY", 8 == birthday.length() ? birthday : "");
			auth.put("GENDER", f.getInt("gender", 1));
		}

		if(0 < f.getInt("dept_id")) user.item("dept_id", f.getInt("dept_id"));
		user.item("zipcode", f.get("zipcode"));
		user.item("addr", f.get("addr"));
		user.item("new_addr", f.get("new_addr"));
		user.item("addr_dtl", f.get("addr_dtl"));
		user.item("email", email);
		user.item("etc1", f.get("etc1"));
		user.item("etc2", f.get("etc2"));
		user.item("etc3", f.get("etc3"));
		user.item("etc4", f.get("etc4"));
		user.item("etc5", f.get("etc5"));

		user.item("email_yn", emailYn);
		user.item("sms_yn", smsYn);

		uinfo.put("email", email);

		auth.put("EMAIL", email);
		if(changeEmailYn) {
			agreementLog.insertLog(siteinfo, uinfo, "email", emailYn, "modify");

			p.setVar("type", m.getValue("email", agreementLog.typesMsg));
			p.setVar("agreement_yn", m.getValue(emailYn, agreementLog.receiveYnMsg));
			p.setVar("reg_date", m.time(_message.get("format.date.local")));
			//mailTemplate.sendMail(siteinfo, uinfo, "receive", m.getItem("email", agreementLog.types) + " 수신정보가 변경되었습니다.", p);
			mail.send(siteinfo, uinfo, "receive", p);
		}
		if(changeSmsYn) {
			agreementLog.insertLog(siteinfo, uinfo, "sms", smsYn, "modify");

			p.setVar("type", m.getValue("sms", agreementLog.typesMsg));
			p.setVar("agreement_yn", m.getValue(smsYn, agreementLog.receiveYnMsg));
			p.setVar("reg_date", m.time(_message.get("format.date.local")));
			//mailTemplate.sendMail(siteinfo, uinfo, "receive", m.getItem("sms", agreementLog.types) + " 수신정보가 변경되었습니다.", p);
			mail.send(siteinfo, uinfo, "receive", p);
		}

		//파일리사이징
		/*if(isUpload) {
			try {
				String imgPath = m.getUploadPath(f.getFileName("user_file"));
				String cmd = "convert -resize 500x " + imgPath + " " + imgPath;
				Runtime.getRuntime().exec(cmd);
			}
			catch(Exception e) { }
		}*/

		if(!user.update("id = " + userId)) {
			m.jsAlert(_message.get("alert.common.error_modify"));
			m.js("parent.resetPassword();");
			return;
		}

		auth.setAuthInfo();

		m.jsAlert(
			_message.get("alert.member.modified")
			+ (changeEmailYn || changeSmsYn ? _message.get("alert.member.modified_subscribe.prefix", new String[] {"site_nm=>" + siteinfo.s("site_nm")}) : "")
			+ (changeEmailYn ? _message.get("alert.member.modified_subscribe.email", new String[] {"email_receive_yn=>" + m.getValue(emailYn, agreementLog.receiveYnMsg)}) : "")
			+ (changeSmsYn ? _message.get("alert.member.modified_subscribe.sms", new String[] {"sms_receive_yn=>" + m.getValue(smsYn, agreementLog.receiveYnMsg)}) : "")
			+ (changeEmailYn || changeSmsYn ? _message.get("alert.member.modified_subscribe.suffix", new String[] {"site_nm=>" + siteinfo.s("site_nm")}) + _message.get("alert.member.modified_subscribe.date", new String[] {"today=>" + m.time(_message.get("format.date.local"))}) : "")
		);

		int utime = m.getUnixTime();
		String ekey = m.encrypt(utime + "|" + loginId + "|" + key, "SHA-256");
		m.jsReplace("modify.jsp?ek=" + ekey + "&ut=" + utime, "parent");
		return;
	}
} else {
	f.addElement("email_yn", uinfo.s("email_yn"), "hname:'이메일수신동의'");
	f.addElement("sms_yn", uinfo.s("sms_yn"), "hname:'SMS수신동의'");

	//수정
	if(m.isPost() && f.validate()) {
		String emailYn = f.get("email_yn", "N");
		String smsYn = f.get("sms_yn", "N");
		boolean changeEmailYn = !uinfo.s("email_yn").equals(emailYn);
		boolean changeSmsYn = !uinfo.s("sms_yn").equals(smsYn);

		user.item("email_yn", emailYn);
		user.item("sms_yn", smsYn);

		if(changeEmailYn) {
			agreementLog.insertLog(siteinfo, uinfo, "email", emailYn, "modify");

			p.setVar("type", m.getValue("email", agreementLog.typesMsg));
			p.setVar("agreement_yn", m.getValue(emailYn, agreementLog.receiveYnMsg));
			p.setVar("reg_date", m.time(_message.get("format.date.local")));
			//mailTemplate.sendMail(siteinfo, uinfo, "receive", m.getItem("email", agreementLog.types) + " 수신정보가 변경되었습니다.", p);
			mail.send(siteinfo, uinfo, "receive", p);
		}
		if(changeSmsYn) {
			agreementLog.insertLog(siteinfo, uinfo, "sms", smsYn, "modify");

			p.setVar("type", m.getValue("sms", agreementLog.typesMsg));
			p.setVar("agreement_yn", m.getValue(smsYn, agreementLog.receiveYnMsg));
			p.setVar("reg_date", m.time(_message.get("format.date.local")));
			//mailTemplate.sendMail(siteinfo, uinfo, "receive", m.getItem("sms", agreementLog.types) + " 수신정보가 변경되었습니다.", p);
			mail.send(siteinfo, uinfo, "receive", p);
		}

		if(!user.update("id = " + userId)) {
			m.jsAlert(_message.get("alert.common.error_modify"));
			return;
		}

		m.jsAlert(
			_message.get("alert.member.modified")
			+ (changeEmailYn || changeSmsYn ? _message.get("alert.member.modified_subscribe.prefix", new String[] {"site_nm=>" + siteinfo.s("site_nm")}) : "")
			+ (changeEmailYn ? _message.get("alert.member.modified_subscribe.email", new String[] {"email_receive_yn=>" + m.getValue(emailYn, agreementLog.receiveYnMsg)}) : "")
			+ (changeSmsYn ? _message.get("alert.member.modified_subscribe.sms", new String[] {"sms_receive_yn=>" + m.getValue(smsYn, agreementLog.receiveYnMsg)}) : "")
			+ (changeEmailYn || changeSmsYn ? _message.get("alert.member.modified_subscribe.suffix", new String[] {"site_nm=>" + siteinfo.s("site_nm")}) + _message.get("alert.member.modified_subscribe.date", new String[] {"today=>" + m.time(_message.get("format.date.local"))}) : "")
		);

		//m.jsAlert(_message.get("alert.member.modified"));
		m.jsReplace("index.jsp", "parent");
		return;

	}
}

//포맷팅
uinfo.put("gender_conv", m.getValue(uinfo.s("gender"), user.gendersMsg));
uinfo.put("birthday_conv", m.time(_message.get("format.date.local"), uinfo.s("birthday")));
if(!"".equals(uinfo.s("user_file"))) uinfo.put("user_file_url", m.getUploadUrl(uinfo.s("user_file")));

//출력
p.setLayout(ch);
p.setBody("mypage.modify");
p.setVar("p_title", "회원정보수정");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("view_block", isSSO);
p.setVar(uinfo);

p.setVar("is_auth", isAuth);
p.setLoop("dept_list", userDept.getList(siteId, "U", 0));
p.setLoop("years", mcal.getYears(m.addDate("Y", -49, sysToday, "yyyy")));
p.setLoop("months", mcal.getMonths());
p.setLoop("days", mcal.getDays());
p.setLoop("receive_yn", m.arr2loop(user.receiveYn));

p.setVar("file_ek", m.encrypt("LMS@FILE_user_ID" + userId + "_LIST_" + sysToday));
p.setVar("st_year", m.time("yyyy"));
p.setVar("SITE_CONFIG", SiteConfig.getArr(new String[] {"join_", "modify_", "user_etc_"}));

p.setVar("is_sso", isSSO);
p.display();

%>