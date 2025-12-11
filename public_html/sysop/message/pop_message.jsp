<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(41, userId, userKind)) { m.jsAlert("접근 권한이 없습니다."); m.js("parent.CloseLayer();"); return; }

String idx = m.rs("idx");

//객체
MessageDao message = new MessageDao();
MessageUserDao messageUser = new MessageUserDao();
UserDao user = new UserDao(isBlindUser);

//변수
String now = m.time("yyyyMMddHHmmss");

//폼체크
f.addElement("subject", null, "hname:'제목', required:'Y'");

if(m.isPost() && f.validate()) {

	int newId = message.getSequence();
	message.item("id", newId);
	message.item("site_id", siteId);
	message.item("module", "user");
	message.item("module_id", 0);
	message.item("user_id", userId);
	message.item("subject", f.get("subject"));
	message.item("content", f.get("content"));
	message.item("reg_date", now);
	message.item("status", 1);

	if(!message.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); m.js("parent.CloseLayer();"); return; }

	int totalCnt = 0;

	String[] tmpArr = m.rs("user_idx").split(",");
	if(tmpArr != null) {
		DataSet userList = user.find("status > -1 AND id IN (" + m.join(",", tmpArr) + ")", "id, user_nm", "id ASC");
		while(userList.next()) {
			messageUser.item("site_id", siteId);
			messageUser.item("message_id", newId);
			messageUser.item("user_id", userList.s("id"));
			messageUser.item("reg_date", now);
			messageUser.item("send_status", 1);
			messageUser.item("read_yn", "N");
			messageUser.item("status", 1);

			if(messageUser.insert()) totalCnt++;
		}

		message.updateSendCnt(newId, totalCnt);
	}
	m.jsAlert("발송되었습니다.");
	m.js("parent.CloseLayer();");
	return;
}

DataSet ulist = user.find("status > -1 AND id IN (" + m.join(",", idx.split(",")) + ")", "id, user_nm, login_id", "id ASC");
while(ulist.next()){
	user.maskInfo(ulist);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && ulist.size() > 0 && !isBlindUser) _log.add("V", "쪽지발송", ulist.size(), "이러닝 운영", ulist);


//출력
p.setLayout("poplayer");
p.setBody("message.pop_message");
p.setVar("p_title", "쪽지발송");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("ulist", ulist);

p.display();

%>