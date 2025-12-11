<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(39, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
MailDao mail = new MailDao();
MailUserDao mailUser = new MailUserDao();
UserDao user = new UserDao();

if(!"".equals(m.rs("idx"))) { //복수삭제
	String idx = m.rs("idx");

	DataSet list = mail.find("id IN (" + idx + ") AND status = 1 AND site_id = " + siteId + "");
	if(list.size() == 0) { m.jsError("해당 정보가 없습니다."); return; }

	if(-1 == mail.execute("UPDATE " + mail.table + " SET status = -1 WHERE id IN ( " + idx + " )")) {
		m.jsError("삭제하는 중 오류가 발생했습니다.");
		return;
	}

} else if(m.ri("id") != 0) { //개별삭제

	int id = m.ri("id");
	//정보
	DataSet info = mail.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

	if(-1 == mail.execute("UPDATE " + mail.table + " SET status = -1 WHERE id = " + id + "")) {
		m.jsError("삭제하는 중 오류가 발생했습니다.");
		return;
	}

} else {
	m.jsError("기본키는 반드시 지정해야 합니다.");
	return;
}

m.jsReplace("mail_list.jsp");

%>