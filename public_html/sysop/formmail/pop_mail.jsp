<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String fid = m.rs("fid");
if("".equals(fid)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); m.js("parent.parent.CloseLayer();"); return; }

//객체
MailDao mail = new MailDao();
MailUserDao mailUser = new MailUserDao();
MailTemplateDao mailTemplate = new MailTemplateDao();
UserDao user = new UserDao(isBlindUser);
FormmailDao formmail = new FormmailDao();

if("".equals(siteinfo.s("site_email"))) siteinfo.put("site_email", "webmaster@" + siteinfo.s("domain"));
String sender = siteinfo.s("site_email");

//폼체크
f.addElement("subject", "질문하신 사항에 답변이 등록되었습니다.", "hname:'제목', required:'Y'");
f.addElement("sender", sender, "hname:'발송자', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");

//변수
boolean isSend = true;

//정보-폼메일
DataSet finfo = formmail.query(
	"SELECT a.*"
	+ " FROM " + formmail.table + " a"
	+ " WHERE a.id = " + fid + " AND (a.email IS NOT NULL OR a.email != '')"
);
while(finfo.next()) {
	user.maskInfo(finfo);
}

//기록-개인정보조회
if(finfo.size() > 0 && !isBlindUser) _log.add("V", "게시판목록", finfo.size(), "이러닝 운영", finfo);

//템플릿
Page p2 = new Page(tplRoot);
p2.setRoot(siteinfo.s("doc_root") + "/html");
p2.setVar("pinfo", finfo);
p2.setVar("content", "[editor]");
String[] template = m.split("[editor]", mailTemplate.fetchTemplate(siteId, "qna_answer", p2));

//등록
if(m.isPost() && f.validate()) {
	p2.setVar("content", f.get("content"));
	if(!mail.send(siteinfo, finfo.s("email"), "qna_answer", p2)) {
		m.jsAlert("발송하는 중 오류가 발생했습니다.");
	} else {
		m.jsAlert("발송되었습니다.");
		m.js("parent.CloseLayer();");
	}
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("formmail.pop_mail");
p.setVar("p_title", "메일발송");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(finfo);

p.setVar("is_send", isSend);
p.setVar("template_header", template[0]);
p.setVar("template_footer", template[1]);
p.display();
%>