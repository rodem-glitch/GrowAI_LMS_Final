<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(126, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
MailTemplateDao mailTemplate = new MailTemplateDao();
UserDao user = new UserDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = mailTemplate.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("status_conv", m.getItem(info.s("status"), mailTemplate.statusList));

//템플릿복사
if(1 == siteId && "COPY".equals(m.rs("mode"))) {
	m.jsAlert(mailTemplate.copyTemplate(info.s("template_cd")) + "개 사이트에 복사되었습니다.");
	m.jsReplace("template_modify.jsp?" + m.qs("mode"));
	return;
}

//폼체크
f.addElement("template_nm", info.s("template_nm"), "hname:'템플릿명', required:'Y'");
f.addElement("subject", info.s("subject"), "hname:'발송제목', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
f.addElement("copies", info.s("copy_idx"), "hname:'사본수신자'");
if(1 == siteId) f.addElement("base_yn", info.s("base_yn"), "hname:'기본템플릿여부', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태'");

//수정
if(m.isPost() && f.validate()) {

	mailTemplate.item("template_nm", f.get("template_nm"));
	mailTemplate.item("subject", f.get("subject"));
	mailTemplate.item("content", f.get("content"));
	mailTemplate.item("copy_idx", "|" + m.join("|", f.getArr("copy_id")) + "|");
	if(1 == siteId) mailTemplate.item("base_yn", f.get("base_yn", "N"));
	mailTemplate.item("status", f.get("status", "0"));

	if(!mailTemplate.update("id = " + id)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("template_list.jsp?" + m.qs("id"), "parent");
	return;
}

//출력
p.setBody("mail.template_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("copy_list", user.find("status = 1 AND id IN ('" + m.replace(info.s("copy_idx"), "|", "','") + "')"));
p.setLoop("status_list", m.arr2loop(mailTemplate.statusList));
p.display();

%>