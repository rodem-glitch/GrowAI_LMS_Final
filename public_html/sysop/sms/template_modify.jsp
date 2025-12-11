<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(133, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = smsTemplate.query(
	" SELECT a.*, st.content default_content "
	+ " FROM " + smsTemplate.table + " a "
	+ " LEFT JOIN " + smsTemplate.table + " st ON a.base_yn = 'Y' AND a.template_cd = st.template_cd AND st.site_id = 1 "
	+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1 "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("status_conv", m.getItem(info.s("status"), smsTemplate.statusList));

//템플릿복사
if(1 == siteId && "COPY".equals(m.rs("mode"))) {
	m.jsAlert(smsTemplate.copyTemplate(info.s("template_cd")) + "개 사이트에 복사되었습니다.");
	m.jsReplace("template_modify.jsp?" + m.qs("mode"));
	return;
}

//폼체크
f.addElement("template_nm", info.s("template_nm"), "hname:'템플릿명', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
if(1 == siteId) f.addElement("base_yn", info.s("base_yn"), "hname:'기본템플릿여부', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태'");

//수정
if(m.isPost() && f.validate()) {

	smsTemplate.item("template_nm", f.get("template_nm"));
	smsTemplate.item("content", f.get("content"));
	if(1 == siteId) smsTemplate.item("base_yn", f.get("base_yn", "N"));
	smsTemplate.item("status", f.get("status", "1"));

	if(!smsTemplate.update("id = " + id)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("template_list.jsp?" + m.qs("id"), "parent");
	return;
}

//출력
p.setBody("sms.template_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("status_list", m.arr2loop(smsTemplate.statusList));
p.display();

%>