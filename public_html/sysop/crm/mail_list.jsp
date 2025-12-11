<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
MailDao mail = new MailDao();
MailUserDao mailUser = new MailUserDao();

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(
	mail.table + " a "
	+ " INNER JOIN " + mailUser.table + " b ON a.id = b.mail_id AND b.send_yn = 'Y'"
	+ " INNER JOIN " + user.table + " ru ON b.user_id = ru.id AND ru.site_id = " + siteId + " AND ru.status != -1 "
	+ " LEFT JOIN " + user.table + " c ON a.user_id = c.id "
);
lm.setFields("a.*, c.user_nm, c.login_id");
lm.addWhere("a.status != -1");
lm.addWhere("b.user_id = " + uid + "");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("subject_conv", m.cutString(list.s("subject"), 65));
	
	if(list.i("user_id") == -9) {
		list.put("user_nm", "(자동)");
		list.put("login_id", "SYSTEM");
	}
}

//출력
p.setLayout(ch);
p.setBody("crm.mail_list");

p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setLoop("list", list);

p.setVar("tab_sent", "current");
p.setVar("tab_sub_mail", "current");
p.display();

%>