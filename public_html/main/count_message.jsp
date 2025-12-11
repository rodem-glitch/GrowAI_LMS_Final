<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { out.print("0"); return; }

//객체
MessageDao message = new MessageDao();
MessageUserDao mu = new MessageUserDao();

//변수
String today = m.time("yyyyMMdd");

//쿠폰수
int messageCnt = mu.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + mu.table + " a "
	+ " INNER JOIN " + message.table + " b ON a.message_id = b.id "
	+ " WHERE a.user_id = " + userId + " "
	+ " AND a.status = 1 AND a.read_yn = 'N' "
);

out.print(messageCnt);

%>