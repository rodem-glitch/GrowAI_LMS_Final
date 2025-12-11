<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(40, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);

//폼체크
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	sms.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id "
);
lm.setFields("a.*, b.user_nm, b.login_id");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
if(!"".equals(f.get("s_sdate"))) lm.addWhere("a.reg_date >= '" + m.time("yyyyMMdd000000", f.get("s_sdate")) + "'");
if(!"".equals(f.get("s_edate"))) lm.addWhere("a.reg_date <= '" + m.time("yyyyMMdd235959", f.get("s_edate")) + "'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.content, b.user_nm, b.login_id", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("content_conv", m.cutString(list.s("content"), 60));
	list.put("resend_block", list.i("resend_id") > 0);
	list.put("send_cnt", m.nf(list.i("send_cnt")));
	list.put("fail_cnt", m.nf(list.i("fail_cnt")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("t_link", "group".equals(list.s("module")) ? "_group" : "");

	if(list.i("user_id") == -9) {
		list.put("user_nm", "(자동)");
		list.put("login_id", "SYSTEM");
	}

	list.put("sms_type_conv", m.getItem(list.s("sms_type"), sms.alltypes));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "SMS발송관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "user_nm=>발송자(성명)","login_id=>회원아이디", "sender=>발송자(휴대전화)", "content=>내용", "send_cnt=>발송건수", "fail_cnt=>실패건수", "reg_date_conv=>등록일"}, "SMS발송관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("sms.sms_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.display();

%>