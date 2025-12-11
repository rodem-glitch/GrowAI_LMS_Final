<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
UserDao user = new UserDao();
MailDao mail = new MailDao();
WebpageDao webpage = new WebpageDao();
AgreementLogDao agreementLog = new AgreementLogDao(p, siteId);

//제한
String ek = m.encrypt("PRIVACY_" + id + "_AGREE_" + m.time("yyyyMMdd"));
if(!ek.equals(m.rs("ek"))) {
	m.jsError(_message.get("alert.common.abnormal_access"));
	return;
}

//정보
DataSet info = user.find("id = " + id + " AND site_id = " + siteId + " AND status = 1");
if(!info.next()) {
	m.jsError(_message.get("alert.member.nodata"));
	return;
}

//개인정보활용에 동의함 | (SSO 사용 & SSO 개인정보약관 사용안함)
if("Y".equals(info.s("privacy_yn"))
	|| (siteinfo.b("sso_yn")
	&& !siteinfo.b("sso_privacy_yn"))
) {
	m.redirect("/main/index.jsp");
	return;
}

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"join_", "modify_", "user_etc_"});
boolean joinBlock = "Y".equals(siteconfig.s("join_config_yn"));

//폼체크
f.addElement("agree_yn1", null, "hname:'이용약관', required:'Y'");
f.addElement("agree_yn2", null, "hname:'개인정보 수집 및 이용', required:'Y'");
f.addElement("email_yn", "Y", "hname:'이메일수신동의'");
f.addElement("sms_yn", "Y", "hname:'SMS수신동의'");
if(joinBlock) {

}

//처리
if(m.isPost() && f.validate()) {

	//변수
	String emailYn = f.get("email_yn", "N");
	String smsYn = f.get("sms_yn", "N");

	//수정
	user.item("email_yn", emailYn);
	user.item("sms_yn", smsYn);
	user.item("privacy_yn", "Y");
	if(!user.update("id = " + id + " AND site_id = " + siteId + " AND status = 1")) {
		m.jsAlert("수정하는 중 오류가 발생했습니다.");
		return;
	}
	if(joinBlock) {
		/*
		f.addElement("user_nm", null, "hname:'성명', required:'Y'");
		if(0 < siteconfig.i("join_dept_status")) f.addElement("dept_id", null, "hname:'회원소속', required:'Y'");
		if(0 < siteconfig.i("join_birthday_status")) f.addElement("birthday_year", null, "hname:'생년월일(년도)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_birthday_status")) f.addElement("birthday_month", null, "hname:'생년월일(월)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_birthday_status")) f.addElement("birthday_day", null, "hname:'생년월일(일)'" + (1 < siteconfig.i("join_birthday_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_gender_status")) f.addElement("gender", null, "hname:'성별', required:'Y'");
		if(0 < siteconfig.i("join_email_status")) f.addElement("email1", null, "hname:'이메일', glue:'email2'" + (1 < siteconfig.i("join_email_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_email_status")) f.addElement("email2", null, "hname:'이메일'" + (1 < siteconfig.i("join_email_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_mobile_status")) f.addElement("mobile1", null, "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_mobile_status")) f.addElement("mobile2", null, "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_mobile_status")) f.addElement("mobile3", null, "hname:'휴대폰번호'" + (1 < siteconfig.i("join_mobile_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_addr_status")) f.addElement("zipcode", null, "hname:'우편번호'" + (1 < siteconfig.i("join_addr_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_addr_status")) f.addElement("addr", null, "hname:'구 주소'");
		if(0 < siteconfig.i("join_addr_status")) f.addElement("new_addr", null, "hname:'도로명 주소'" + (1 < siteconfig.i("join_addr_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_addr_status")) f.addElement("addr_dtl", null, "hname:'상세주소'");
		if(0 < siteconfig.i("join_etc1_status")) f.addElement("etc1", null, "hname:'" + siteconfig.s("user_etc1_nm") + "'" + (1 < siteconfig.i("join_etc1_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_etc2_status")) f.addElement("etc2", null, "hname:'" + siteconfig.s("user_etc2_nm") + "'" + (1 < siteconfig.i("join_etc2_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_etc3_status")) f.addElement("etc3", null, "hname:'" + siteconfig.s("user_etc3_nm") + "'" + (1 < siteconfig.i("join_etc3_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_etc4_status")) f.addElement("etc4", null, "hname:'" + siteconfig.s("user_etc4_nm") + "'" + (1 < siteconfig.i("join_etc4_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_etc5_status")) f.addElement("etc5", null, "hname:'" + siteconfig.s("user_etc5_nm") + "'" + (1 < siteconfig.i("join_etc5_status") ? ", required:'Y'" : ""));
		if(0 < siteconfig.i("join_email_yn_status")) f.addElement("email_yn", "Y", "hname:'이메일수신동의'");
		if(0 < siteconfig.i("join_sms_yn_status")) f.addElement("sms_yn", "Y", "hname:'SMS수신동의'");
		*/
	}

	//동의기록
	agreementLog.insertLog(siteinfo, info, "email", emailYn, "privacy_agree");
	agreementLog.insertLog(siteinfo, info, "sms", smsYn, "privacy_agree");
	agreementLog.insertLog(siteinfo, info, "privacy", "Y", "privacy_agree");

	//메일-이메일동의여부
	p.setVar("type", m.getValue("email", agreementLog.typesMsg));
	p.setVar("agreement_yn", m.getValue(emailYn, agreementLog.receiveYnMsg));
	p.setVar("reg_date", m.time(_message.get("format.date.local")));
	mail.send(siteinfo, info, "receive", p);

	//메일-SMS동의여부
	p.setVar("type", m.getValue("sms", agreementLog.typesMsg));
	p.setVar("agreement_yn", m.getValue(smsYn, agreementLog.receiveYnMsg));
	p.setVar("reg_date", m.time(_message.get("format.date.local")));
	mail.send(siteinfo, info, "receive", p);

	//이동
	m.jsAlert("처리가 완료되었습니다. 다시 로그인 해 주세요.");
	m.jsReplace("/member/login.jsp", "parent");
	return;
}

//출력
p.setLayout(ch);
p.setBody("member.privacy_agree");
p.setVar("form_script", f.getScript());

p.setVar("clause", webpage.getOne("SELECT content FROM " + webpage.table + " WHERE code = 'clause' AND site_id = " + siteId + " AND status = 1"));
p.setLoop("receive_yn", m.arr2loop(user.receiveYn));

p.setVar("join_block", joinBlock);
p.display();

%>