<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.apache.commons.net.ftp.*" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(-998, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
String type = m.rs("type", "U");
String snm = m.rs("snm");

//제한
if(!superBlock && !"U".equals(type)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ShortcutDao shortcut = new ShortcutDao(siteId);

//폼체크
f.addElement("shortcut_nm", snm, "hname:'퀵메뉴명', required:'Y'");
f.addElement("link", null, "hname:'링크', required:'Y'");
f.addElement("target", "_blank", "hname:'링크타겟', required:'Y'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {
	int shortcutUserId = "S".equals(type) ? -99 : userId;
	int maxSort = shortcut.findCount("site_id = " + siteId + " AND user_id = " + shortcutUserId + " AND status = 1");

	shortcut.item("site_id", siteId);
	shortcut.item("user_id", shortcutUserId);
	shortcut.item("shortcut_nm", f.get("shortcut_nm"));
	shortcut.item("link", f.get("link"));
	shortcut.item("target", f.get("target"));
	shortcut.item("sort", maxSort + 1);
	shortcut.item("reg_date", m.time("yyyyMMddHHmmss"));
	shortcut.item("status", f.get("status"));

	//등록
	if(!shortcut.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("../shortcut/shortcut_list.jsp?" + m.qs(), "parent");
	m.js("parent.parent._Menu.location.href = parent.parent._Menu.location.href;");
	m.js("parent.CloseLayer();");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("shortcut.pop_shortcut_insert");
p.setVar("p_title", "퀵메뉴 등록");

p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("targets", m.arr2loop(shortcut.targets));
p.setLoop("status_list", m.arr2loop(shortcut.statusList));
p.display();

%>