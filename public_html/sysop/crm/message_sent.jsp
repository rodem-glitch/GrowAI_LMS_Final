<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
MessageDao message = new MessageDao();
MessageUserDao messageUser = new MessageUserDao();

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum(20);
lm.setTable(
	message.table + " a "
	+ " INNER JOIN " + messageUser.table + " b ON a.id = b.message_id "
	+ " INNER JOIN " + user.table + " ru ON b.user_id = ru.id AND ru.status != -1 "
	+ " INNER JOIN " + user.table + " c ON b.user_id = c.id AND c.status != -1 "
);
lm.setFields("a.*, b.id mid, b.read_yn, b.read_date, c.login_id receive_user_id, c.user_nm receive_user_nm");
lm.addWhere("a.user_id = " + uid);
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")));
	list.put("read_yn_str", m.getItem(list.s("read_yn"), messageUser.readList));
	list.put("subject_conv", m.cutString(list.s("subject"), 35));
	list.put("read_date_conv", !"".equals(list.s("read_date")) ? m.time("yyyy.MM.dd HH:mm:ss", list.s("read_date")) : "-");
}

//출력
p.setLayout(ch);
p.setBody("crm.message_sent");
p.setVar("query", m.qs());
p.setVar("list_total", lm.getTotalString());

p.setVar("pagebar", lm.getPaging());
p.setLoop("list", list);

p.setVar("tab_sent", "current");
p.setVar("tab_sub_message", "current");
p.display();

%>