<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!Menu.accessible(91, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
MainpageDao mainpage = new MainpageDao();

//수정
if(m.isPost()) {
	if(f.getArr("module_id") != null) {
		int sort = 0;

		for(int i = 0; i < f.getArr("module_id").length; i++) {
			mainpage.item("sort", ++sort);
			if(!mainpage.update("id = " + f.getArr("module_id")[i] + " AND site_id = " + siteId)) { }
		}
	}

	m.jsAlert("수정되었습니다.");
	m.jsReplace("mainpage_list.jsp?" + m.qs(), "parent");
	return;
}

//목록
String[] displayYn = { "Y=>보임", "N=>숨김" };
DataSet list = mainpage.find("site_id = " + siteId + " AND status != -1", "*", "sort ASC");
while(list.next()) {
	list.put("module_type_conv", m.getItem(list.s("module_type"), mainpage.modules));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), displayYn));
}

//출력
p.setBody("design.mainpage_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);

p.display();

%>