<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(-998, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(1 > id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ShortcutDao shortcut = new ShortcutDao(siteId);

//정보
DataSet info = shortcut.find("id = ? AND site_id = " + siteId, new Integer[] { id });
if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); m.js("parent.CloseLayer();"); return; }

shortcut.item("status", -1);
if(!shortcut.update("id = " + id)) { m.jsAlert("삭제하는 중 오류가 발생했습니다."); m.js("parent.CloseLayer();"); return; }

//닫기
m.jsReplace("../shortcut/shortcut_list.jsp?" + m.qs(), "parent");
m.js("parent.parent._Menu.location.href = parent.parent._Menu.location.href;");
m.js("parent.CloseLayer();");

%>