<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.apache.commons.net.ftp.*" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(-998, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(1 > id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//폼입력
String type = m.rs("type", "U");

//제한
if(!superBlock && !"U".equals(type)) { m.jsError("접근 권한이 없습니다."); return; }

//변수
int shortcutUserId = "S".equals(type) ? -99 : userId;

//객체
ShortcutDao shortcut = new ShortcutDao(siteId);

//정보
DataSet info = shortcut.find("id = ? AND user_id = ? AND site_id = " + siteId + " AND status != -1", new Integer[] { id, shortcutUserId });
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("shortcut_nm", info.s("shortcut_nm"), "hname:'퀵메뉴명', required:'Y'");
f.addElement("link", info.s("link"), "hname:'링크', required:'Y'");
f.addElement("target", info.s("target"), "hname:'링크타겟', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {
	shortcut.item("shortcut_nm", f.get("shortcut_nm"));
	shortcut.item("link", f.get("link"));
	shortcut.item("target", f.get("target"));
	shortcut.item("status", f.get("status"));

	//수정
	if(!shortcut.update("id = " + id)) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("../shortcut/shortcut_list.jsp?" + m.qs("id"), "parent");
	m.js("parent.parent._Menu.location.href = parent.parent._Menu.location.href;");
	m.js("parent.CloseLayer();");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("shortcut.pop_shortcut_insert");
p.setVar("p_title", "퀵메뉴 수정");

p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setLoop("targets", m.arr2loop(shortcut.targets));
p.setLoop("status_list", m.arr2loop(shortcut.statusList));
p.display();

%>