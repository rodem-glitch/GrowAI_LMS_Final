<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(122, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("webtv");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();
WebtvDao webtv = new WebtvDao();

int id = -1000 - siteId;
String[] idx = m.reqArr("idx");

if(idx != null && idx.length > 0) {

	String[] displayYn = m.reqArr("display_yn");
	for(int i=0; i<idx.length; i++) {
		webtv.item("allsort", i);
		//course.item("display_yn", displayYn[i]);
		webtv.update("id = " + idx[i]);
	}

	m.redirect("category_all_modify.jsp");
	return;
}

//정보
DataSet info = category.find("id = " + id + " AND status = 1 AND site_id = " + siteId + " AND module = 'webtv'");
if(!info.next()) {
	category.item("id", id);
	category.item("site_id", siteId);
	category.item("module", "webtv");
	category.item("parent_id", -1);
	category.item("category_nm", "카테고리");
	category.item("list_type", "gallery");
	category.item("sort_type", "id desc");
	category.item("list_num", 20);
	category.item("display_yn", "Y");
	category.item("target_yn", "N");
	category.item("login_yn", "N");
	category.item("hit_cycle", 24);
	category.item("depth", 0);
	category.item("sort", 0);
	category.item("status", 1);
	category.insert();
}

//폼체크
f.addElement("category_nm", "카테고리", null);
f.addElement("list_type", info.s("list_type"), "hname:'과정목록타입', required:'Y'");
f.addElement("sort_type", info.s("sort_type"), "hname:'과정정렬순서', required:'Y'");
f.addElement("list_num", info.i("list_num"), "hname:'목록갯수', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	category.item("list_type", f.get("list_type", "gallery"));
	category.item("sort_type", f.get("sort_type", "id DESC"));
	category.item("list_num", f.get("list_num", "20"));

	if(!category.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.js("parent.left.location.href='category_tree.jsp?" + m.qs() + "&sid=" + id + "';");
	m.jsReplace("category_all_modify.jsp");
	return;
}

DataSet list = webtv.find("site_id = " + siteId + " AND status != -1 ORDER BY allsort, id DESC");
while(list.next()) {
	list.put("webtv_nm_conv", m.cutString(list.s("webtv_nm"), 40));
	list.put("status_conv", m.getItem(list.s("status"), webtv.statusList));
	list.put("display_conv", m.getItem(list.s("display_yn"), webtv.displayList));
	list.put("open_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("open_date")));
}

//출력
p.setLayout("blank");
p.setBody("webtv.category_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
p.setLoop("list", list);
p.setVar("parent_name", "-");
p.setVar("modify", true);
p.setVar("top", true);
p.setVar("root", true);
p.display();

%>