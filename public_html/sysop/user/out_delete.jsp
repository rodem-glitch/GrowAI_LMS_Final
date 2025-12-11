<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(66, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int uid = m.ri("uid");
if(0 == uid) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
UserOutDao userOut = new UserOutDao();
ActionLogDao actionLog = new ActionLogDao();

//정보
DataSet info = userOut.query(
	" SELECT a.*, u.login_id "
	+ " FROM " + userOut.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id " 
	+ " WHERE a.user_id = ? AND u.site_id = " + siteId
	, new Object[] {uid}
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//변수
String newLoginId = m.getUniqId(32);

//수정-회원
user.item("login_id", newLoginId);
user.item("user_nm", "[탈퇴]");
user.item("passwd", "");
user.item("access_token", "");
user.item("email", "");
user.item("zipcode", "");
user.item("addr", "");
user.item("new_addr", "");
user.item("addr_dtl", "");
user.item("gender", "");
user.item("birthday", "");
user.item("mobile", "");
user.item("etc1", "");
user.item("etc2", "");
user.item("etc3", "");
user.item("etc4", "");
user.item("etc5", "");
user.item("dupinfo", "");
user.item("oauth_vendor", "");
if(!user.update("id = " + uid)) {
	m.jsError("삭제하는 중 오류가 발생했습니다. [E1]");
	return;
}

//액션로그-회원
actionLog.item("site_id", siteId);
actionLog.item("user_id", userId);
actionLog.item("module", "user");
actionLog.item("module_id", info.i("user_id"));
actionLog.item("action_type", "U");
actionLog.item("action_desc", "회원탈퇴 완전삭제(로그인아이디 난수 변경)");
actionLog.item("before_info", info.s("login_id"));
actionLog.item("after_info", newLoginId);
actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
actionLog.item("status", 1);
if(!actionLog.insert()) {
	m.jsError("삭제하는 중 오류가 발생했습니다. [E2]");
	return;
}

//삭제-회원탈퇴
if(0 > userOut.execute("DELETE FROM " + userOut.table + " WHERE user_id = " + uid)) {
	m.jsError("삭제하는 중 오류가 발생했습니다. [E3]");
	return;
}

//액션로그-회원탈퇴
actionLog.item("site_id", siteId);
actionLog.item("user_id", userId);
actionLog.item("module", "user_out");
actionLog.item("module_id", info.i("user_id"));
actionLog.item("action_type", "D");
actionLog.item("action_desc", "회원탈퇴 완전삭제(탈퇴정보삭제)");
actionLog.item("before_info", info.serialize());
actionLog.item("after_info", "");
actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
actionLog.item("status", 1);
if(!actionLog.insert()) {
	m.jsError("삭제하는 중 오류가 발생했습니다. [E3]");
	return;
}

//이동
m.jsReplace("out_list.jsp?" + m.qs("uid"));
return;

%>