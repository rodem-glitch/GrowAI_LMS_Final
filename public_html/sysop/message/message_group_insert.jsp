<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(41, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
MessageDao message = new MessageDao();
UserDao user = new UserDao();
MessageUserDao messageUser = new MessageUserDao();
GroupDao group = new GroupDao();
GroupUserDao groupUser = new GroupUserDao();

//폼체크
f.addElement("subject", null, "hname:'제목', required:'Y'");
f.addElement("content", null, "hname:'내용', required:'Y'");
f.addElement("group_id", null, "hname:'회원그룹', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	//정보
	DataSet ginfo = group.find("id = '" + f.getInt("group_id") + "' AND site_id = " + siteinfo.i("id") + "");
	if(!ginfo.next()) { m.jsAlert("해당 그룹 정보가 없습니다."); return; }
	String depts = !"".equals(ginfo.s("depts")) ? m.replace(ginfo.s("depts").substring(1, ginfo.s("depts").length()-1), "|", ",") : "";


	//변수
	int newId = message.getSequence();

	message.item("id", newId);
	message.item("site_id", siteinfo.i("id"));
	message.item("module", "group");
	message.item("module_id", f.getInt("group_id"));

	message.item("user_id", userId);
	message.item("subject", f.get("subject"));
	message.item("content", f.get("content"));
	message.item("resend_id", 0);
	message.item("send_cnt", 0);
	message.item("reg_date", m.time("yyyyMMddHHmmss"));
	message.item("status", 1);

	if(!message.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	DataSet users = user.query(
		"SELECT a.* "
		+ " FROM " + user.table + " a "
		+ " WHERE a.site_id = " + siteinfo.i("id") + " "
		+ (!"".equals(depts)
				? " AND a.status = 1 AND ( a.dept_id IN (" + depts + ") OR "
				: " AND ( a.status = 1 AND ")
		+ " EXISTS ( "
			+ " SELECT 1 FROM " + groupUser.table + " "
			+ " WHERE group_id = " + f.get("group_id") + " AND add_type = 'A' "
			+ " AND user_id = a.id "
		+ " ) ) AND NOT EXISTS ( "
			+ " SELECT 1 FROM " + groupUser.table + " "
			+ " WHERE group_id = " + f.get("group_id") + " AND add_type = 'D' "
			+ " AND user_id = a.id "
		+ " ) "
	);

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

	m.jsReplace("message_list.jsp?" + m.qs("id"), "parent");
	return;
}

//목록
DataSet groups = group.find("status = 1 AND site_id = " + siteinfo.i("id") + "", "*", "group_nm ASC");

//출력
p.setBody("message.message_group_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("t_link", "insert");
p.setLoop("groups", groups);
p.display();

%>