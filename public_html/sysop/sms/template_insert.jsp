<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(133, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

//코드체크
if("CHECK".equals(m.rs("mode"))) {
	String value = m.rs("v");
	if("".equals(value)) { return; }

	//중복여부
	if(0 < smsTemplate.findCount("template_cd = '" + value + "' AND site_id = " + siteId)) {
		out.print("<span class='bad'>사용 중인 코드입니다. 다시 입력해 주세요.</span>");
	} else {
		out.print("<span class='good'>사용할 수 있는 코드입니다.</span>");
	}
	return;
}

//폼체크
f.addElement("template_cd", null, "hname:'템플릿코드', required:'Y', max:20, maxlength:20, pattern:'^[a-z]{1}[a-z0-9_]{1,19}$', errmsg:'영문 소문자로 시작하는 2-10자의 영문 소문자, 숫자, _ 조합으로 입력하세요.'");
f.addElement("template_nm", null, "hname:'템플릿명', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
if(1 == siteId) f.addElement("base_yn", "Y", "hname:'기본템플릿여부', required:'Y'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	//중복검사-코드
	if(0 < smsTemplate.findCount("template_cd = '" + f.get("template_cd") + "' AND site_id = " + siteId)) { m.jsAlert("사용 중인 코드입니다. 다시 입력해 주세요."); return; }

	smsTemplate.item("site_id", siteId);
	smsTemplate.item("template_cd", f.get("template_cd"));
	smsTemplate.item("template_nm", f.get("template_nm"));
	smsTemplate.item("content", f.get("content"));
	if(1 == siteId) smsTemplate.item("base_yn", f.get("base_yn", "N"));
	smsTemplate.item("reg_date", m.time("yyyyMMddHHmmss"));
	smsTemplate.item("status", f.get("status", "0"));

	if(!smsTemplate.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("template_list.jsp?" + m.qs(), "parent");
	return;
}

//출력
p.setBody("sms.template_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(smsTemplate.statusList));
p.display();

%>