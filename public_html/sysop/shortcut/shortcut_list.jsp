<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(-998, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
String type = m.rs("type", "U");

//제한
if(!superBlock && !"U".equals(type)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ShortcutDao shortcut = new ShortcutDao(siteId);

//수정
if(m.isPost() && f.validate()) {
	if(f.getArr("shortcut_id") != null) {
		for(int i = 0; i < f.getArr("shortcut_id").length; i++) {
			shortcut.item("sort", i + 1);
			if(!shortcut.update("id = " + f.getArr("shortcut_id")[i] + " AND site_id = " + siteId)) { }
		}
	}

	m.jsAlert("수정되었습니다.");
	m.js("parent.parent._Menu.location.href = parent.parent._Menu.location.href;");
	m.jsReplace("shortcut_list.jsp?" + m.qs(), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(1000000);
lm.setTable(shortcut.table + " a");
lm.setFields("a.*");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.user_id = " + ("S".equals(type) ? -99 : userId) + "");
lm.addWhere("a.status != -1");
lm.setOrderBy("a.sort ASC, a.id ASC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("target_conv", m.getItem(list.s("target"), shortcut.targets));
	list.put("status_conv", m.getItem(list.s("status"), shortcut.statusList));
}

//출력
p.setBody("shortcut.shortcut_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);

p.setVar("tab_" + type, "current");
p.setLoop("status_list", m.arr2loop(shortcut.statusList));
p.display();

%>