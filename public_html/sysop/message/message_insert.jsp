<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(41, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
MessageDao message = new MessageDao();
UserDao user = new UserDao();
MessageUserDao messageUser = new MessageUserDao();

//답장
int mid = m.ri("mid");
DataSet minfo = new DataSet();
DataSet userList = new DataSet();
if(mid != 0) {
	minfo = message.query(
		"SELECT a.*, u.user_nm, u.login_id "
		+ " FROM " + message.table + " a "
		+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
		+ " WHERE a.id = " + mid + " AND a.status != -1 "
		+ " AND a.site_id = " + siteinfo.i("id") + " "
	);
	if(!minfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
	minfo.put("subject", "[답장] " + minfo.s("subject"));
	minfo.put("content", "\n\n\n\n-----------------------------원문-----------------------------\n\n" + minfo.s("content"));

	userList = messageUser.query(
		"SELECT u.* "
		+ " FROM " + messageUser.table + " a "
		+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
		+ " WHERE a.message_id = " + mid + " "
	);
}

//폼체크
f.addElement("subject", minfo.s("subject"), "hname:'제목', required:'Y'");
f.addElement("content", null, "hname:'내용', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int newId = message.getSequence();

	message.item("id", newId);
	message.item("site_id", siteinfo.i("id"));

	message.item("module", "user");
	message.item("module_id", 0);
	message.item("user_id", userId);
	message.item("subject", f.get("subject"));
	message.item("content", f.get("content"));
	message.item("resend_id", 0);
	message.item("send_cnt", 0);
	message.item("reg_date", m.time("yyyyMMddHHmmss"));
	message.item("status", 1);

	if(!message.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	String[] tmpArr = m.rs("user_idx").split(",");
	DataSet users = user.find("id IN ('" + m.join("','", tmpArr) + "')", "*", "id ASC");

	int totalCnt = 0;

	messageUser.item("site_id", siteId);
	messageUser.item("message_id", newId);
	messageUser.item("read_yn", "N");
	messageUser.item("read_date", "");
	messageUser.item("send_status", 1);
	messageUser.item("reg_date", m.time("yyyyMMddHHmmss"));
	messageUser.item("status", 1);
	while(users.next()) {
		messageUser.item("user_id", users.i("id"));
		if(messageUser.insert()) { totalCnt++; }
	}

	//갱신
	message.execute("UPDATE " + message.table + " SET send_cnt = " + totalCnt + " WHERE id = " + newId);

	//이동
	m.jsReplace("message_list.jsp?" + m.qs("id"), "parent");
	return;
}

//출력
p.setBody("message.message_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(minfo);
p.setLoop("users", userList);

p.setVar("t_link", "insert");
p.display();

%>