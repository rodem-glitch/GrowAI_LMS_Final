<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(66, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserOutDao userOut = new UserOutDao();
UserDao user = new UserDao();
ActionLogDao actionLog = new ActionLogDao();

if(!"".equals(m.rs("idx"))) { //복수삭제
	String[] idx = m.rs("idx").split("\\,");
	int failed = 0;
	for(int i = 0; i < idx.length; i++) {
		DataSet info = userOut.find("user_id = " + idx[i] + " AND status != -1");
		if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

		userOut.item("admin_id", userId);
		userOut.item("out_date", m.time("yyyyMMddHHmmss"));

		if(userOut.update("user_id = " + idx[i])) {
			info = user.find("id = " + idx[i] + " AND status != -1");
			if(info.next()) {
				if(!user.deleteUser(Integer.parseInt(idx[i]))) {}

				//액션로그
				actionLog.item("site_id", siteId);
				actionLog.item("user_id", userId);
				actionLog.item("module", "user");
				actionLog.item("module_id", info.i("id"));
				actionLog.item("action_type", "D");
				actionLog.item("action_desc", "탈퇴승인");
				actionLog.item("before_info", info.serialize());
				actionLog.item("after_info", "");
				actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
				actionLog.item("status", 1);
				if(!actionLog.insert()) {}
			}
		} else {
			failed++;
		}
	}
	if(failed > 0) {
		m.jsError("삭제하는 중 오류가 발생했습니다. (실패/전체 : " + failed + "/" + idx.length + ")");
		return;
	}
} else if(!"".equals(m.rs("uid"))) { //개별삭제
	DataSet info = userOut.find("user_id = " + m.ri("uid") + " AND status != -1");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

	userOut.item("admin_id", userId);
	userOut.item("out_date", m.time("yyyyMMddHHmmss"));

	if(userOut.update("user_id = " + m.ri("uid"))) {
		info = user.find("id = " + m.ri("uid") + " AND status != -1");
		if(info.next()) {
			if(!user.deleteUser(m.ri("uid"))) {}

			//액션로그
			actionLog.item("site_id", siteId);
			actionLog.item("user_id", userId);
			actionLog.item("module", "user");
			actionLog.item("module_id", info.i("id"));
			actionLog.item("action_type", "D");
			actionLog.item("action_desc", "탈퇴승인");
			actionLog.item("before_info", info.serialize());
			actionLog.item("after_info", "");
			actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
			actionLog.item("status", 1);
			if(!actionLog.insert()) {}
		}
	}

} else {
	m.jsError("기본키는 반드시 지정해야 합니다.");
	return;
}

m.jsReplace("out_list.jsp?" + m.qs("uid, idx"));
