<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
MessageDao message = new MessageDao();
MessageUserDao messageUser = new MessageUserDao();

//유효성검사
int mid = m.ri("mid");
if(mid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

DataSet info = message.query(
	"SELECT a.*, c.login_id receive_user_id, b.read_yn, b.read_date, c.user_nm receive_user_nm "
	+ " FROM " + message.table + " a "
	+ "INNER JOIN " + messageUser.table + " b ON a.id = b.message_id "
	+ "INNER JOIN " + user.table + " ru ON b.user_id = ru.id AND ru.status != -1 "
	+ "INNER JOIN " + user.table + " c ON b.user_id = c.id AND c.status != -1 "
	+ "WHERE b.id = " + mid + " AND a.user_id = " + uid
);
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

info.put("read_yn_str", m.getItem(info.s("read_yn"), messageUser.readList));
info.put("read_date_conv", !"".equals(info.s("read_date")) ? m.time("yyyy.MM.dd HH:mm:ss", info.s("read_date")) : "-");
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));

//출력
p.setLayout(ch);
p.setBody("crm.message_sent_view");
p.setVar("p_title", "보낸쪽지 상세보기");
p.setVar("list_query", m.qs("mid"));

p.setVar(info);

p.setVar("tab_sent", "current");
p.display();

%>