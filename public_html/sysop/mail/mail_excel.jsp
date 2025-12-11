<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(39, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
MailDao mail = new MailDao();
MailUserDao mailUser = new MailUserDao();
MailTemplateDao mailTemplate = new MailTemplateDao();
UserDao user = new UserDao();

//샘플다운로드
if("1".equals(m.rs("sample"))) {
	String filename = "sample.xls";
	File f1 = new File(docRoot + "/sysop/mail/sample.xls");

	if(!f1.exists()) {
		m.jsAlert("샘플파일이 없습니다. 관리자에게 문의하세요.");
		return;
	}
	m.download(docRoot + "/sysop/mail/sample.xls", filename);
	return;
}

//폼입력
int id = m.ri("id");

if("".equals(siteinfo.s("site_email"))) siteinfo.put("site_email", "webmaster@" + siteinfo.s("domain"));
String sender = siteinfo.s("site_email");

DataSet info = new DataSet();
if(id == 0) {
	info.addRow();
	info.put("id", 0);
	info.put("sender", sender);
	info.put("subject", "");
	info.put("modify", false);
	info.put("t_link", "insert");
} else {
	info = mail.find("status = 1 AND id = " + id + "");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
	info.put("t_link", "modify");
	info.put("modify", true);
}

//폼체크
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("mail_type", "I", "hname:'메일유형', required:'Y'");
f.addElement("sender", info.s("sender"), "hname:'발송자', required:'Y', allowhtml:'Y'");
f.addElement("att_file", null, "hname:'엑셀파일', required:'Y', allow:'xls|xlsx'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");

//등록
if(m.isPost() && f.validate()) {

	String[] cols = { "col0=>name", "col1=>email" };
	DataSet fields = m.arr2loop(cols);

	File attFile = f.saveFile("att_file");
	if(attFile == null) {
		m.jsAlert("파일 업로드하는데  실패했습니다.");
		return;
	}

	ExcelReader ex = new ExcelReader(attFile.getPath());
	DataSet users = ex.getDataSet();
	users.next(); //첫번째 타이틀은 건너뛴다.
	ex.close();
	attFile.delete();
	if(users.size() < 2) { m.jsAlert("대상회원이 없습니다."); return; }

	//변수
	int newId = mail.getSequence();

	mail.item("id", newId);
	mail.item("site_id", siteId);
	mail.item("module", "excel");
	mail.item("module_id", 0);
	mail.item("user_id", userId);
	mail.item("mail_type", "I");
	mail.item("sender", f.get("sender"));
	mail.item("subject", f.get("subject"));
	mail.item("content", f.get("content"));
	mail.item("resend_id", info.i("id"));
	mail.item("send_cnt", 0);
	mail.item("fail_cnt", 0);
	mail.item("reg_date", m.time("yyyyMMddHHmmss"));
	mail.item("status", 1);

	if(!mail.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//템플릿
	p.setRoot(siteinfo.s("doc_root") + "/html");
	p.setVar("SITE_INFO", siteinfo);
	p.setVar("subject", f.get("subject"));
	p.setVar("MBODY", f.get("content"));

	//메일 발송
	m.mailFrom = f.get("sender");
	String subject = "[" + siteinfo.s("site_nm") + "] " + f.get("subject");

	int sendCnt = 0;
	int failCnt = 0;
	while(users.next()) {
		mailUser.item("site_id", siteId);
		mailUser.item("mail_id", newId);
		mailUser.item("email", users.s("col1"));
		mailUser.item("user_id", "-99"); //엑셀
		mailUser.item("user_nm", users.s("col0"));
		if(mail.isMail(users.s("col1"))) {
			mailUser.item("send_yn", "Y");
			if(mailUser.insert()) {
				if(isSend) m.mail(users.s("col1"), subject, p.fetchRoot("mail/template.html"));
				sendCnt++;
			}
		} else {
			mailUser.item("send_yn", "N");
			if(mailUser.insert()) { failCnt++; }
		}
	}

	//발송건수
	mail.execute("UPDATE " + mail.table + " SET send_cnt = " + sendCnt + ", fail_cnt = " + failCnt + " WHERE id = " + newId + "");

	m.jsReplace("mail_list.jsp?" + m.qs("id"), "parent");
	return;
}

//출력
p.setBody("mail.mail_excel");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
//p.setLoop("templates", m.arr2loop(mail.templates));
p.setLoop("templates", mailTemplate.getList(siteId));
p.setLoop("types", m.arr2loop(mail.types));
p.display();

%>