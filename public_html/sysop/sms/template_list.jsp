<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(133, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

//폼체크
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(smsTemplate.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.template_cd, a.template_nm, a.content", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("template_nm_conv", m.cutString(list.s("template_nm"), 100));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), smsTemplate.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "메일템플릿관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "template_cd=>템플릿코드", "template_nm=>템플릿명", "content=>내용", "status_conv=>상태" }, "메일템플릿관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//테스트====================
p.setVar("course_nm", "과정명!");
p.setVar("end_date_conv", "2018.01.22");
DataSet tempInfo = new UserDao().find("id = 1");
tempInfo.next();
//m.p("" + smsTemplate.sendSms(siteinfo, tempInfo, "course_renew", p, "T1"));
//테스트====================

//출력
p.setBody("sms.template_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(smsTemplate.statusList));
p.display();


%>