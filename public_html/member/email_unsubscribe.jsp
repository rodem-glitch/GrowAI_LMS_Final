<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//제한
String ek = m.rs("ek");
int key = m.ri("k");
if(!ek.equals(m.encrypt(key + "_" + siteId + "_EMAIL_UNSUBSCRIBE"))) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//객체
UserDao user = new UserDao();
MailUserDao mailUser = new MailUserDao();
MailDao mail = new MailDao();
AgreementLogDao agreementLog = new AgreementLogDao(p, siteId);

//정보-회원
DataSet uinfo = mailUser.query(
	" SELECT a.mail_id, u.email "
	+ " FROM " + mailUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " AND u.status = 1 "
	+ " WHERE a.id = " + key
);
if(!uinfo.next()) { m.jsAlert(_message.get("alert.common.abnormal_access")); return; }

//수정
if(m.isPost() && f.validate()) {
	
	DataSet ulist = user.find("email = '" + uinfo.s("email") + "' AND status = 1");
	while(ulist.next()) {
		user.item("email_yn", "N");
		if(!user.update("id = " + ulist.i("id"))) { m.jsAlert(_message.get("alert.common.error_modify")); return; }

		agreementLog.insertLog(siteinfo, ulist, "email", "N", "mail", ulist.i("mail_id"));
	}

	//메일
	p.setVar("type", m.getValue("email", agreementLog.typesMsg));
	p.setVar("agreement_yn", m.getValue("N", agreementLog.receiveYnMsg));
	p.setVar("reg_date", m.time(_message.get("format.date.local")));
	mail.send(siteinfo, ulist, "receive", p);

	m.jsAlert(
		_message.get("alert.member.unsubscribe_email"
		, new String[] {"site_nm=>" + siteinfo.s("site_nm"), "today=>" + m.time(_message.get("format.date.local"))})
	);

	m.jsReplace("../main/index.jsp", "parent");
	return;
}

//출력
p.setLayout(ch);
p.setBody(ch + ".email_unsubscribe");
p.setVar("query", m.qs("mode"));
p.setVar("form_script", f.getScript());

p.setVar(uinfo);

p.display();

%>