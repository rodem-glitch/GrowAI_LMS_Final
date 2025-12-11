<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
MessageDao message = new MessageDao();
MessageUserDao messageUser = new MessageUserDao();

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setFields("a.*, b.read_yn, c.user_nm, c.login_id");
lm.setTable(
	message.table + " a "
	+ " INNER JOIN " + messageUser.table + " b ON a.id = b.message_id "
	+ " INNER JOIN " + user.table + " ru ON b.user_id = ru.id AND ru.status != -1 "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id AND c.status != -1 "
);
lm.addWhere("b.send_status = 1");
lm.addWhere("b.user_id = " + uid);
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("read_conv", list.b("read_yn") ? "수신" : "미수신");
	list.put("subject_conv", m.cutString(list.s("subject"), 30));
}

//출력
p.setLayout(ch);
p.setBody("crm.message_list");
p.setVar("query", m.qs());

p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setLoop("list", list);

p.setVar("tab_sent", "current");
p.setVar("tab_sub_message", "current");
p.display();

%>