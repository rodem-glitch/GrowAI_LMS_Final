<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ActionLogDao actionLog = new ActionLogDao();

//정보
DataSet info = user.find("id = " + uid + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsAlert("해당 회원정보가 없습니다."); return; }

//권한
if(!("S".equals(userKind) || (!"S".equals(info.s("user_kind")) && userId != info.i("id")))) { m.jsAlert("권한이 없습니다."); m.js("parent.parent.CloseLayer();"); return; }

//폼체크
f.addElement("login_id", null, "hname:'아이디', required:'Y'");

//처리
if("CHECK".equals(m.rs("mode"))) {
	String value = m.rs("v");
	if("".equals(value)) { return; }

	//중복여부
	if(0 < user.findCount("id != " + uid + " AND login_id = '" + value.toLowerCase() + "' AND site_id = " + siteId + "")) {
		out.print("<span class='bad'>사용 중인 아이디입니다. 다시 입력해 주세요.</span>");
	} else {
		out.print("<span class='good'>사용할 수 있는 아이디입니다.</span>");
	}
	return;
}

//수정
if(m.isPost() && f.validate()) {
	
	//중복여부
	if(0 < user.findCount("id != " + uid + " AND login_id = '" + f.get("login_id").toLowerCase() + "' AND site_id = " + siteId + "")) {
		m.jsAlert("사용 중인 아이디입니다. 다시 입력해 주세요.");
		return;
	}

	//등록-로그
	actionLog.item("site_id", siteId);
	actionLog.item("user_id", userId);
	actionLog.item("module", "user");
	actionLog.item("module_id", uid);
	actionLog.item("action_type", "U");
	actionLog.item("action_desc", "로그인아이디 수정");
	actionLog.item("before_info", info.s("login_id"));
	actionLog.item("after_info", f.get("login_id"));
	actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
	actionLog.item("status", 1);
	if(!actionLog.insert()) { m.jsAlert("로그를 등록하는 중 오류가 발생했습니다."); return; }

	//수정
	user.item("login_id", f.get("login_id"));
	if(!user.update("id = " + uid)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//세션삭제
	if(-1 == UserSession.execute("UPDATE " + UserSession.table + " SET session_id = 'login_id_modify_" + sysNow + "', mod_date = '" + sysNow + "' WHERE user_id = " + uid + " AND site_id = " + siteId)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("../crm/user_modify.jsp?" + m.qs(), "parent.parent");
	m.js("parent.parent.CloseLayer();");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("crm.user_loginid_modify");
p.setVar("p_title", "아이디 수정");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.display();

%>