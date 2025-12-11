<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
MessageUserDao messageUser = new MessageUserDao();

if(!"".equals(m.rs("idx"))) {
	//복수삭제
	String[] idx = m.rs("idx").split("\\,");
	int failed = 0;
	for(int i = 0; i < idx.length; i++) {
		if(-1 == messageUser.execute(
			"UPDATE " + messageUser.table + " SET status = -1 WHERE id = ? AND site_id = " + siteId + " AND status = 1 "
			, new Integer[] { m.parseInt(idx[i]) }
		)) failed++;
	}
	if(failed > 0) {
		m.jsError(_message.get("alert.common.error_delete_detail", new String[] {"failed=>" + failed, "total=>" + idx.length}));
		return;
	}
} else if(0 != m.ri("id")) {
	//개별삭제

	//정보
	DataSet info = messageUser.find("id = ? AND site_id = " + siteId + " AND status = 1", new Integer[] { m.ri("id") });
	if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

	//삭제
	messageUser.item("status", -1);
	if(!messageUser.update("id = " + info.i("id"))) {
		m.jsError(_message.get("alert.common.error_delete"));
		return;
	}

} else {
	m.jsError(_message.get("alert.common.required_key"));
	return;
}

//이동
m.jsReplace("message_list.jsp?" + m.qs("id, idx"));

%>