<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//기본키
String[] idx = f.getArr("idx");
if("".equals(idx)) { m.jsErrClose("기본키는 반드시 입력해야 합니다."); return; }

//객체
MessageDao message = new MessageDao();
MessageUserDao messageUser = new MessageUserDao();
UserDao user = new UserDao(isBlindUser);
CourseUserDao courseUser = new CourseUserDao();

//변수
String now = m.time("yyyyMMddHHmmss");

//폼체크
f.addElement("subject", null, "hname:'제목', required:'Y'");

//등록
if("insert".equals(f.get("p_type")) && m.isPost() && f.validate()) {

	int newId = message.getSequence();
	message.item("id", newId);
	message.item("site_id", siteId);
	message.item("module", "course");
	message.item("module_id", courseId);
	message.item("user_id", userId);
	message.item("subject", f.get("subject"));
	message.item("content", f.get("content"));
	message.item("reg_date", now);
	message.item("status", 1);

	if(!message.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	String[] tmpArr = m.rs("user_idx").split(",");
	DataSet userList = user.find("status > -1 AND id IN (" + m.join(",", tmpArr) + ")", "*", "id ASC");

	int sendCnt = 0;
	while(userList.next()) {
		messageUser.item("site_id", siteId);
		messageUser.item("message_id", newId);
		messageUser.item("user_id", userList.i("id"));
		messageUser.item("read_yn", "N");
		messageUser.item("read_date", "");
		messageUser.item("reg_date", now);
		messageUser.item("send_status", 1);
		messageUser.item("status", 1);

		if(messageUser.insert()) sendCnt++;
	}

	message.execute("UPDATE " + message.table + " SET send_cnt = " + sendCnt + " WHERE id = " + newId + "");
	m.jsErrClose("발송되었습니다", "parent");
	return;
}

//발송회원리스트
DataSet users = new DataSet();
if(idx != null) {
	users = user.query(
		"SELECT a.id, a.user_nm, a.login_id "
		+ " FROM " + user.table + " a "
		+ " WHERE a.id IN (" + (m.join(",", idx)) + ") "
		+ " AND EXISTS ( "
			+ " SELECT id FROM " + courseUser.table + " "
			+ " WHERE user_id = a.id AND course_id = " + courseId + " AND status IN (1, 3) "
		+ " )"
	);
}
while (users.next()){
	user.maskInfo(users);
}

//기록-개인정보조회
if(users.size() > 0 && !isBlindUser) _log.add("V", "쪽지발송", users.size(), "이러닝 운영", users);

//출력
p.setLayout("pop");
p.setBody("management.pop_message");
p.setVar("p_title", "쪽지발송");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

//p.setVar("content", "<p style='font-weight: bold;'>[" + info.s("course_nm") + "]</p><p></p>");
p.setLoop("users", users);
p.display();
%>