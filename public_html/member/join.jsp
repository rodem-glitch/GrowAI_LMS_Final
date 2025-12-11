<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.regex.Pattern" %>
<%@ page import="malgnsoft.json.*" %>
<%@ include file="init.jsp" %><%

//로그인
if(userId != 0) { m.redirect("../main/index.jsp"); return; }

//SSO
if(siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"))) {
	String url = siteinfo.s("sso_url") + ( siteinfo.s("sso_url").indexOf("?") > -1 ?  "&mode=join" : "?mode=join");
	m.redirect(url);
	return;
}

//제한
String ek = m.rs("ek");
String key = m.rs("k");
if(!ek.equals(m.encrypt(key + "_AGREE"))) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//제한
if(0 > siteinfo.i("join_status")) {
	m.jsAlert(_message.get("alert.member.stop_join"));
	m.jsReplace("/");
	return;
}

//변수
String marketYn = "N";
String emailYn = "N";
String smsYn = "N";

//마케팅동의여부
marketYn = "Y".equals(m.getCookie("market_yn")) ? "Y" : "N";
emailYn = "Y".equals(m.getCookie("email_yn")) ? "Y" : "N";
smsYn = "Y".equals(m.getCookie("sms_yn")) ? "Y" : "N";



//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"join_", "modify_", "user_etc_", "ktalk_"});

//객체
UserDao user = new UserDao(); user.setInsertIgnore(true);
UserDeptDao userDept = new UserDeptDao();
AgreementLogDao agreementLog = new AgreementLogDao(p, siteId);
MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
FileDao file = new FileDao();
MCal mcal = new MCal(); mcal.yearRange = 50;

SmsDao sms = new SmsDao(siteId);
if(siteinfo.b("sms_yn")) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));
KtalkDao ktalk = new KtalkDao(siteId);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId);

//이동-가입설정사용여부
if("Y".equals(siteconfig.s("join_config_yn"))) {
	m.redirect("join2.jsp?" + m.qs());
	return;
}

//변수-미리입력된정보
DataSet ainfo = new DataSet();
boolean loginIdBlock = false;
boolean userNmBlock = false;
boolean passwdBlock = false;
boolean birthdayBlock = false;
boolean genderBlock = false;
boolean emailBlock = false;
boolean mobileBlock = false;
String pattern = "(\\d{3})(\\d{3,4})(\\d{4})";

//타사계정로그인
boolean isOAuth = "oauth".equals(mSession.s("join_method"));
if(isOAuth) {
	DataSet temp = new DataSet();
	try { temp = Json.decode(mSession.s("join_data")); }
	catch(JSONException jsone) { m.errorLog("JSONException : " + jsone.getMessage(), jsone); m.jsError(_message.get("alert.common.error_view")); return; }
	catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); m.jsError(_message.get("alert.common.error_view")); return; }
	if(!temp.next()) { m.jsError(_message.get("alert.common.error_view")); return; }

	ainfo.addRow();
	ainfo.put("login_id", mSession.s("join_vendor") + "_" + temp.s("id"));
	ainfo.put("user_nm", temp.s("name"));
	loginIdBlock = true;
	userNmBlock = true;
	passwdBlock = true;

	if("naver".equals(mSession.s("join_vendor"))) {
		ainfo.put("email", temp.s("email"));
		ainfo.put("gender", "M".equals(temp.s("gender")) ? "1" : "2");
		ainfo.put("gender_conv", m.getValue(ainfo.s("gender"), user.gendersMsg));
		emailBlock = true;
		genderBlock = true;
	} else if("facebook".equals(mSession.s("join_vendor"))
			|| "google".equals(mSession.s("join_vendor"))
			|| "kakao".equals(mSession.s("join_vendor"))) {
		ainfo.put("email", temp.s("email"));
		emailBlock = true;
	//} else if("sba".equals(mSession.s("join_vendor"))) {
	//	userNmBlock = false;
	}

	//제한
	if(isOAuth && 0 < user.findCount("login_id = '" + ainfo.s("login_id") + "' AND site_id = " + siteId + "")) {
		m.jsError(_message.get("alert.member.used_oauth"));
		return;
	}
}

//본인인증-NICE
boolean isAuth = (siteinfo.b("auth_yn") || siteinfo.b("ipin_yn"));
if(isAuth) {
	//타사계정로그인과 동시 적용시 addRow하면 타사계정로그인정보가 날아감.
	if(!isOAuth) ainfo.addRow();

	//타사계정로그인에서 정보가 있는데 본인인증에서 빈 값이 들어올 때 빈 값으로 덮어쓰는걸 방지.
	//본인인증에서 들어오는 값이 빈 값이 아니면 더 신뢰성이 높은 본인인증 정보로 덮어씀
	if(!"".equals(mSession.s("sName"))) { ainfo.put("user_nm", mSession.s("sName")); userNmBlock = true; }
	if(!"".equals(mSession.s("sGenderCode"))) { ainfo.put("gender_code", mSession.s("sGenderCode")); genderBlock = true; }
	if(!"".equals(mSession.s("sBirthDate"))) { ainfo.put("birthday", mSession.s("sBirthDate")); birthdayBlock = true; }
	if(!"".equals(mSession.s("sMobileNo"))) { ainfo.put("mobile", mSession.s("sMobileNo")); mobileBlock = true; }
	ainfo.put("dupinfo", mSession.s("sDupInfo")); //중복가입 확인값 (DI - 64 byte 고유값)
	ainfo.put("national_info", mSession.s("sNationalInfo")); //내/외국인 정보 (개발 가이드 참조)

	//포맷팅
	ainfo.put("gender", "0".equals(ainfo.s("gender_code")) ? "2" : ainfo.s("gender_code"));
	ainfo.put("gender_conv", m.getValue(ainfo.s("gender"), user.gendersMsg));
	ainfo.put("birthday_conv", m.time(_message.get("format.date.local"), ainfo.s("birthday")));
	ainfo.put("mobile_conv", ainfo.s("mobile").replaceAll(pattern, "$1-$2-$3"));

	//제한
	if("".equals(ainfo.s("dupinfo"))) { m.jsAlert(_message.get("alert.auth.nodupinfo")); return; }
	if(0 < user.findCount("dupinfo = '" + ainfo.s("dupinfo") + "' AND status != -1")) {
		if(!"125.129.123.211".equals(userIp)) {
			m.jsAlert(_message.get("alert.member.used_dupinfo"));
			m.jsReplace("../" + (!isGoMobile ? "member" : "mobile") + "/login.jsp");
		} else {
			out.print(_message.get("alert.member.used_dupinfo") + "<br>" + ainfo.s("dupinfo"));
		}
		return;
	}
}

//처리
if("CHECK".equals(m.rs("mode"))) {
	String value = m.rs("v");
	if("".equals(value)) { return; }

	//중복여부
	if(0 < user.findCount("login_id = ? AND site_id = ?", new Object[] {value.toLowerCase(), siteId})) {
		out.print("<span class='bad'>" + _message.get("alert.member.used_id") + "</span>");
	} else {
		out.print("<span class='good'>사용할 수 있는 로그인아이디입니다.</span>");
	}
	return;
} else if("EMAIL".equals(m.rs("mode"))) {
	//변수
	String email = f.get("e").toLowerCase();

	//제한
	if(0 < user.findCount("email = ? AND site_id = ? AND user_kind = 'U' AND status = 1", new Object[] {email, siteId})) { m.jsAlert(_message.get("alert.member.used_email_detail", new String[] {"email=>" + email})); return; }

	//발송
	int authNo = m.getRandInt(123456, 864198);
	p.setVar("auth_no", authNo + "");
	mail.send(siteinfo, email, "findpw_authno", p);

	//세션
	mSession.put("JOIN_EMAIL", email);
	mSession.put("JOIN_AUTHNO", "" + authNo);
	mSession.put("JOIN_SITEID", "" + siteId);
	mSession.put("JOIN_EMAIL_VERIFIED", "");
	mSession.put("JOIN_EMAIL_VERIFYDATE", "");
	mSession.save();

	m.jsAlert(_message.get("alert.member.find.authno_to_email"));
	m.js("try { parent.setVerify(); } catch(e) {}");
	return;
} else if("VERIFY".equals(m.rs("mode"))) {
	//변수
	String email = f.get("e").toLowerCase();
	String code = f.get("c");

	//제한-이메일
	if(0 < user.findCount("email = ? AND site_id = ? AND user_kind = 'U' AND status = 1", new Object[] {email, siteId})) { m.jsAlert(_message.get("alert.member.used_email_detail", new String[] {"email=>" + email})); return; }

	//제한-인증번호
	String authEmail = mSession.s("JOIN_EMAIL");
	String authNo = mSession.s("JOIN_AUTHNO");
	int authSiteId = mSession.i("JOIN_SITEID");

	if(!authEmail.equals(email) || !authNo.equals(code) || siteId != authSiteId) {
		m.jsAlert(_message.get("alert.member.email_fail"));
		return;
	}

	//세션
	mSession.put("JOIN_EMAIL_VERIFIED", email);
	mSession.put("JOIN_EMAIL_VERIFYDATE", m.time("yyyyMMdd"));
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

//폼체크
if(!loginIdBlock) f.addElement("login_id", null, "hname:'로그인아이디', required:'Y', pattern:'^[a-zA-Z]{1}[a-zA-Z0-9]{1,19}$', errmsg:'영문으로 시작하는 2-20자 영문, 숫자 조합을 입력하세요.'");
if(!userNmBlock) f.addElement("user_nm", null, "hname:'성명', required:'Y'");
if(!passwdBlock) f.addElement("passwd", null, "hname:'비밀번호', required:'Y', minbyte:'9', match:'passwd2'");
if(!passwdBlock) f.addElement("passwd2", null, "hname:'비밀번호', required:'Y', minbyte:'9'");
if(!birthdayBlock) f.addElement("birthday_year", null, "hname:'생년월일(년도)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
if(!birthdayBlock) f.addElement("birthday_month", null, "hname:'생년월일(월)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
if(!birthdayBlock) f.addElement("birthday_day", null, "hname:'생년월일(일)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
//f.addElement("dept_id", siteinfo.s("dept_id"), "hname:'회원소속'");
f.addElement("dept_id", null, "hname:'회원소속'");
if(!genderBlock) f.addElement("gender", null, "hname:'성별'" + (1 < siteconfig.i("join_gender_status") ? ", required:'Y'" : ""));
if(!emailBlock) f.addElement("email1", null, "hname:'이메일', required:'Y', glue:'email2'");
if(!emailBlock) f.addElement("email2", null, "hname:'이메일', required:'Y'");
if(!mobileBlock) f.addElement("mobile1", null, "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
if(!mobileBlock) f.addElement("mobile2", null, "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
if(!mobileBlock) f.addElement("mobile3", null, "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
f.addElement("zipcode", null, "hname:'우편번호'");
f.addElement("addr", null, "hname:'구 주소'");
f.addElement("new_addr", null, "hname:'도로명 주소'");
f.addElement("addr_dtl", null, "hname:'상세주소'");
f.addElement("user_file", null, "hname:'사진'");
f.addElement("user_file_k", null, "hname:'사진'");
f.addElement("user_file_ek", null, "hname:'사진'");
f.addElement("email_yn", "Y", "hname:'이메일수신동의'");
f.addElement("sms_yn", "Y", "hname:'SMS수신동의'");

//가입
if(m.isPost() && f.validate()) {

	//제한
	if(!isOAuth && 0 < user.findCount("login_id = ? AND site_id = ?", new Object[] {f.get("login_id").toLowerCase(), siteId})) {
		m.jsAlert(_message.get("alert.member.used_id"));
		m.js("parent.resetPassword();");
		return;
	}

	//제한-비밀번호
	if(!passwdBlock && !f.get("passwd").matches("^(?=.*?[A-Za-z])(?=.*?[0-9])(?=.*?[\\W_]).{9,}$")) {
		m.jsAlert(_message.get("alert.member.rule_password"));
		return;
	}

	String email = (emailBlock ? ainfo.s("email") : f.glue("@", "email1,email2").toLowerCase());
	if(!"@".equals(email)) {
		if(!emailBlock && !mail.isMail(email)) {
			m.jsAlert(_message.get("alert.member.unvalid_email"));
			m.js("parent.resetPassword();");
			return;
		}

		if(!emailBlock && 0 < user.findCount("email = ? AND site_id = ? AND user_kind = 'U' AND status = 1", new Object[] {email, siteId})) {
			m.jsAlert(_message.get("alert.member.used_email_detail", new String[] {"email=>" + email}));
			m.js("parent.resetPassword();");
			return;
		}
	} else {
		email = "";
	}

	int newId = user.getSequence();
//	String emailYn = f.get("email_yn", "N");
//	String smsYn = f.get("sms_yn", "N");
	String passwd = passwdBlock ? "" : f.get("passwd");
	if(64 > passwd.length()) passwd = m.encrypt(passwd, "SHA-256");

	//제한-휴대폰
	String mobile = "";
	if(!mobileBlock) {
		if(!"Y".equals(SiteConfig.s("foreign_yn"))) {
			if(!"".equals(f.get("mobile2")) || !"".equals(f.get("mobile3"))) {
				mobile = f.get("mobile1") + f.get("mobile2") + f.get("mobile3");
				if(!Pattern.matches(pattern, mobile)) {
					m.jsAlert(_message.get("alert.member.unvalid_mobile"));
					m.js("parent.resetPassword();");
					return;
				}
				mobile = mobile.replaceAll(pattern, "$1-$2-$3");
			}
		} else {
			mobile = f.get("mobile1");
		}
	} else {
		mobile = ainfo.s("mobile").replaceAll(pattern, "$1-$2-$3");
	}

	//인증-이메일
	if("Y".equals(siteinfo.s("verify_email_yn"))) {
		if(!email.equals(mSession.s("JOIN_EMAIL_VERIFIED"))
			|| !m.time("yyyyMMdd").equals(mSession.s("JOIN_EMAIL_VERIFYDATE"))
			|| !"Y".equals(f.get("verify_email_yn", "N"))) {
			m.jsAlert(_message.get("alert.member.email_expired"));
			m.js("parent.resetPassword();");
			return;
		}
	}

	user.item("id", newId);
	user.item("site_id", siteId);
	user.item("login_id", loginIdBlock ? ainfo.s("login_id") : f.get("login_id").toLowerCase());
	user.item("user_nm", userNmBlock ? ainfo.s("user_nm") : f.get("user_nm"));
	user.item("passwd", passwd);
	user.item("user_kind", "U");
	user.item("email", email);
	user.item("gender", genderBlock ? ainfo.s("gender") : f.getInt("gender", 1));
	user.item("birthday", birthdayBlock ? ainfo.s("birthday") : f.get("birthday_year") + f.get("birthday_month") + f.get("birthday_day"));

	user.item("mobile", mobile);
	user.item("zipcode", f.get("zipcode"));
	user.item("addr", f.get("addr"));
	user.item("new_addr", f.get("new_addr"));
	user.item("addr_dtl", f.get("addr_dtl"));
	user.item("dept_id", f.getInt("dept_id", siteinfo.i("dept_id")));
	user.item("conn_date", "");
	user.item("etc1", f.get("etc1"));
	user.item("etc2", f.get("etc2"));
	user.item("etc3", f.get("etc3"));
	user.item("etc4", f.get("etc4"));
	user.item("etc5", f.get("etc5"));
	user.item("dupinfo", isAuth ? ainfo.s("dupinfo") : "");
	user.item("oauth_vendor", mSession.s("join_vendor"));

	//파일
	if("Y".equals(SiteConfig.s("join_userfile_yn"))) {
		int tempId = f.getInt("temp_id");
		if(0 > tempId) {
			file.item("module_id", newId);
			if(!file.update("module_id = " + tempId)) { }
		}
	}

//	user.item("email_yn", emailYn);
//	user.item("sms_yn", smsYn);
	user.item("email_yn", "Y".equals(marketYn) ? emailYn : f.get("email_yn"));
	user.item("sms_yn", "Y".equals(marketYn) ? smsYn : f.get("sms_yn"));
	user.item("privacy_yn", "Y");
	user.item("passwd_date", m.addDate("d", siteinfo.i("passwd_day"), m.time("yyyyMMdd"), "yyyyMMdd"));
	user.item("conn_date", m.time("yyyyMMddHHmmss"));
	user.item("reg_date", m.time("yyyyMMddHHmmss"));
	user.item("status", ("0".equals(siteinfo.s("join_status")) ? "0" : "1"));

	if(!user.insert()) {
		m.jsAlert(_message.get("alert.common.error_insert"));
		m.js("parent.resetPassword();");
		return;
	}

	//정보
	DataSet info = user.find("id = " + newId + "");
	if(!info.next()) { }

//	agreementLog.insertLog(siteinfo, info, "email", emailYn, "join");
//	agreementLog.insertLog(siteinfo, info, "sms", smsYn, "join");
	agreementLog.insertLog(siteinfo, info, "marketing", marketYn, "join");
	agreementLog.insertLog(siteinfo, info, "email", "Y".equals(marketYn) ? emailYn : f.get("email_yn"), "join");
	agreementLog.insertLog(siteinfo, info, "sms", "Y".equals(marketYn) ? smsYn : f.get("sms_yn"), "join");
	agreementLog.insertLog(siteinfo, info, "privacy", "Y", "join");

	//메일
	info.put("reg_date_conv", m.time(_message.get("format.datetime.local")));
	p.setVar("info", info);
	mail.send(siteinfo, info, "join", p);
	if("Y".equals(siteconfig.s("ktalk_yn"))) {
		p.setVar("user_nm", info.s("user_nm"));
		ktalkTemplate.sendKtalk(siteinfo, info, "join", p);
	} else {
		smsTemplate.sendSms(siteinfo, info, "join", p);
	}

	//세션초기화
	mSession.put("join_method", "");
	mSession.put("join_vendor", "");
	mSession.put("join_vendor_nm", "");
	mSession.put("join_data", "");
	mSession.put("sName", "");
	mSession.put("sGenderCode", "");
	mSession.put("sBirthDate", "");
	mSession.put("sMobileNo", "");
	mSession.put("sDupInfo", "");
	mSession.put("sNationalInfo", "");
	mSession.save();

	if(isSSL) m.jsReplace("http://" + f.get("domain") + "/member/join_success.jsp?ek=" + ek + "&k=" + key + "&uek=" + m.encrypt(newId + "_NEWUSERID") + "&uk=" + newId, "parent");
	else m.jsReplace("join_success.jsp?ek=" + ek + "&k=" + key + "&uek=" + m.encrypt(newId + "_NEWUSERID") + "&uk=" + newId, "parent");

	return;
}

//출력
p.setLayout(!isGoMobile ? ch : "mobile");
p.setBody((!isGoMobile ? ch : "mobile") + ".join");
p.setVar("p_title", "회원가입");
p.setVar("query", m.qs("mode"));
p.setVar("form_script", f.getScript());

p.setVar("ainfo", ainfo);
p.setVar("SITE_CONFIG", siteconfig);

p.setVar("is_auth", isAuth);
p.setVar("is_oauth", isOAuth);
p.setVar("login_id_block", loginIdBlock);
p.setVar("user_nm_block", userNmBlock);
p.setVar("passwd_block", passwdBlock);
p.setVar("email_block", emailBlock);
p.setVar("mobile_block", mobileBlock);
p.setVar("gender_block", genderBlock);
p.setVar("birthday_block", birthdayBlock);
p.setVar("oauth_vendor", mSession.s("join_vendor"));
p.setVar("oauth_vendor_nm", mSession.s("join_vendor_nm"));

//최상위 노출 여부 체크
DataSet rs = userDept.getList(siteId, "U", 0);
DataSet deptList = new DataSet();
while(rs.next()) {
	if("Y".equals(rs.s("display_yn"))) deptList.addRow(rs.getRow());
}

//p.setLoop("dept_list", userDept.getList(siteId, "U", 0));
p.setLoop("dept_list", deptList);
p.setLoop("years", mcal.getYears(m.addDate("Y", -49, m.time("yyyyMMdd"), "yyyy")));
p.setLoop("months", mcal.getMonths());
p.setLoop("days", mcal.getDays());
p.setLoop("receive_yn", m.arr2loop(user.receiveYn));
p.setVar("domain", request.getServerName());
p.setVar("session_id", mSession.s("id"));
p.setVar("temp_id", m.getRandInt(-2000000, 1990000));

p.setVar("sms_yn", "Y".equals(smsYn));
p.setVar("email_yn", "Y".equals(emailYn));
p.setVar("market_yn", "Y".equals(marketYn));

p.display();

%>