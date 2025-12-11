<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

String ch = m.rs("ch", "board");

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"ktalk_"});

//객체
FormmailDao formmail = new FormmailDao();
FileDao file = new FileDao();
SmsDao sms = new SmsDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
MailDao mail = new MailDao();
MailTemplateDao mailTemplate = new MailTemplateDao();
KtalkDao ktalk = new KtalkDao(siteId);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId);

//제한
if("".equals(siteinfo.s("receive_email"))) {
	m.jsError(_message.get("alert.formmail.nosetting"));
	return;
}

//폼체크
f.addElement("category_nm", null, "HNAME:'카테고리명'");
f.addElement("user_nm", null, "HNAME:'담당자', required:'Y'");
f.addElement("mobile1", null, "HNAME:'연락처', required:'Y', option:'number', minbyte:'3', maxbyte:'3'");
f.addElement("mobile2", null, "HNAME:'연락처', required:'Y', option:'number', minbyte:'3', maxbyte:'4'");
f.addElement("mobile3", null, "HNAME:'연락처', required:'Y', option:'number', minbyte:'4', maxbyte:'4'");
f.addElement("email1", null, "HNAME:'이메일', required:'Y', option:'email', glue:'email2', delim:'@'");
f.addElement("email2", null, "HNAME:'이메일', required:'Y'");
f.addElement("content", null, "HNAME:'문의내용', allowhtml:'Y'");

//등록
if(m.isPost() && f.validate()) {
	
	//제한
	if(1 > m.replace(m.stripTags(f.get("content")), "&nbsp;", " ").trim().length()) {
		m.jsAlert(_message.get("alert.common.enter_contents"));
		return;
	}

	String today = m.time("yyyyMMddHHmmss");
	String email = f.glue("@", "email1,email2");
	String mobile = f.glue("-", "mobile1,mobile2,mobile3");
	String mobileEncrypt = "";

	//제한-휴대전화번호
	if(!sms.isMobile(mobile)) {
		m.jsAlert(_message.get("alert.member.unvalid_contact"));
		return;
	}

	mobileEncrypt = SimpleAES.encrypt(mobile);

	//제한-이미지URI및용량
	String content = f.get("content");
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert(_message.get("alert.board.attach_image"));
		return;
	}
	if(60000 < bytes) { m.jsAlert(_message.get("alert.board.over_capacity", new String[] {"maximum=>60000", "bytes=>" + bytes})); return; }

	//등록
	int newId = formmail.getSequence();
	formmail.item("id", newId);
	formmail.item("site_id", siteId);
	formmail.item("user_nm", f.get("user_nm"));
	formmail.item("category_nm", f.get("category_nm"));
	formmail.item("mobile", mobileEncrypt);
	formmail.item("email", email);
	formmail.item("content", content);
	formmail.item("ip_addr", userIp);
	formmail.item("reg_date", today);
	formmail.item("status", 1);
	if(!formmail.insert()) {
		m.jsAlert(_message.get("alert.common.error_insert"));
		return;
	}

	//갱신-임시파일
	file.updateTempFile(f.getInt("temp_id"), newId, "formmail");

	//발송
	p.setVar("user_nm", f.get("user_nm"));
	p.setVar("mobile", mobile);
	p.setVar("email", email);
	p.setVar("category_nm", !"".equals(f.get("category_nm")) ? f.get("category_nm") : "이메일문의");
	p.setVar("content", f.get("content"));
	if("Y".equals(siteconfig.s("ktalk_yn"))) {
		ktalkTemplate.sendKtalk(siteinfo, SimpleAES.encrypt(siteinfo.s("receive_phone")), "formmail", p);
	} else {
		smsTemplate.sendSms(siteinfo, SimpleAES.encrypt(siteinfo.s("receive_phone")), "formmail", p);
	}
	mail.send(siteinfo, siteinfo.s("receive_email"), "formmail", p);

	//이동
	m.jsAlert(_message.get("alert.formmail.inserted"));
	m.js("parent.location.href = parent.location.href");
	return;
}

int tempId = m.getRandInt(-2000000, 1990000);

//출력
p.setLayout(ch);
p.setBody("main.formmail_json");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("temp_id", tempId);
p.setVar("allow_ext", "jpg|jpeg|gif|png|swf|mp4|flv|mov|qt|mpeg|wmv|wma|asf|mp3|avi|wmp|rmp|ra|pdf|hwp|txt|doc|docx|xls|xlsx|ppt|pptx|zip|7z|rar|alz|egg");
p.display();

%>