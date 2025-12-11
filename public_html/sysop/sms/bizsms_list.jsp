<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(114, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
BizSMS bizSMS = new BizSMS();
UserDao user = new UserDao(isBlindUser);

//폼체크
f.addElement("s_req_sdate", null, null);
f.addElement("s_req_edate", null, null);
f.addElement("s_send_sdate", null, null);
f.addElement("s_send_edate", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(bizSMS.table + " a");
lm.setFields("a.cmid, a.umid, a.send_phone, a.dest_phone, a.msg_body, DATE_FORMAT(a.request_time, '%Y-%m-%d %T') request_time, DATE_FORMAT(a.send_time, '%Y-%m-%d %T') send_time, a.exception");
lm.addWhere("a.site_id = " + siteId + "");
if(!"".equals(f.get("s_req_sdate"))) lm.addWhere("a.request_time >= '" + m.time("yyyy-MM-dd 00:00:00", f.get("s_req_sdate")) + "'");
if(!"".equals(f.get("s_req_edate"))) lm.addWhere("a.request_time <= '" + m.time("yyyy-MM-dd 23:59:59", f.get("s_req_edate")) + "'");
if(!"".equals(f.get("s_send_sdate"))) lm.addWhere("a.send_time >= '" + m.time("yyyy-MM-dd 00:00:00", f.get("s_send_sdate")) + "'");
if(!"".equals(f.get("s_send_edate"))) lm.addWhere("a.send_time <= '" + m.time("yyyy-MM-dd 23:59:59", f.get("s_send_edate")) + "'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.umid, a.send_phone, a.dest_phone, a.msg_body", f.get("s_keyword"), "LIKE");
lm.setOrderBy("a.request_time desc, a.cmid desc");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("umid", !"".equals(list.s("umid")) ? list.s("umid") : list.s("exception"));
	list.put("msg_body_conv", m.cutString(list.s("msg_body"), 40));
	list.put("request_time_conv",list.s("request_time"));
	list.put("send_time_conv", list.s("send_time"));

	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "SMS발신로그(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "umid=>UMID","send_phone=>발신번호", "dest_phone=>수신번호", "msg_body=>내용", "request_time_conv=>등록일시", "send_time_conv=>발신일시"}, "SMS발신로그(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("sms.bizsms_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.display();

%>