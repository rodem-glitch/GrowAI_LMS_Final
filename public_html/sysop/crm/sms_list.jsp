<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
SmsDao sms = new SmsDao(siteId);
SmsUserDao smsUser = new SmsUserDao();
if(siteinfo.b("sms_yn")) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(
	sms.table + " a "
	+ " INNER JOIN " + smsUser.table + " b ON a.id = b.sms_id AND b.send_yn = 'Y' "
	+ " LEFT JOIN " + user.table + " c ON a.user_id = c.id AND c.status != -1 "
);
lm.setFields("a.*, c.login_id, c.user_nm");
lm.addWhere("a.status != -1");
lm.addWhere("b.user_id = " + uid + "");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	if(list.i("user_id") == -9) {
		list.put("user_nm", "(자동)");
		list.put("login_id", "SYSTEM");
	}
}
//출력
p.setLayout(ch);
p.setBody("crm.sms_list");

p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setLoop("list", list);

p.setVar("tab_sent", "current");
p.setVar("tab_sub_sms", "current");
p.display();

%>