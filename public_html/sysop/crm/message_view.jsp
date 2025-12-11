<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
MessageDao message = new MessageDao();
MessageUserDao messageUser = new MessageUserDao();

//유효성검사
int mid = m.ri("mid");
if(mid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = message.query(
	"SELECT a.*, b.read_yn, c.user_nm, c.login_id "
	+ " FROM " + message.table + " a "
	+ " INNER JOIN " + messageUser.table + " b ON a.id = b.message_id AND b.user_id = " + uid
	+ " INNER JOIN " + user.table + " ru ON b.user_id = ru.id AND ru.status != -1 "
	+ " LEFT JOIN " + user.table + " c ON a.user_id = c.id "
	+ " WHERE a.id = " + mid
);
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
info.put("read_yn_str", m.getItem(info.s("read_yn"), new MessageUserDao().readList));

//출력
p.setLayout(ch);
p.setBody("crm.message_view");
p.setVar("p_title", "받은쪽지 상세보기");
p.setVar("list_query", m.qs("mid"));

p.setVar(info);
p.setVar("tab_sent", "current");
p.setVar("tab_sub_message", "current");
p.display();

%>