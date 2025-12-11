<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(109, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("book");
BookDao book = new BookDao();

int id = -1000000 - siteId;

String[] idx = m.reqArr("idx");
if(idx != null && idx.length > 0) {
	for(int i = 0; i < idx.length; i++) {
		book.item("allsort", i);
		book.update("id = " + idx[i]);
	}

	category.item("sort_type", "st asc");
	if(!category.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	m.redirect("category_all_modify.jsp");
	return;
}

//정보
DataSet info = category.find("id = " + id + " AND status = 1 AND site_id = " + siteId + " AND module = 'book'");
if(!info.next()) {
	category.item("id", id);
	category.item("site_id", siteId);
	category.item("module", "book");
	category.item("parent_id", -1);
	category.item("category_nm", "카테고리");
	category.item("list_type", "webzine");
	category.item("sort_type", "id desc");
	category.item("list_num", 20);
	category.item("display_yn", "Y");
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

if(m.isPost() && f.validate()) {

	category.item("list_type", f.get("list_type"));
	category.item("sort_type", f.get("sort_type"));
	category.item("list_num", f.get("list_num"));

	if(!category.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	m.js("parent.left.location.href='category_tree.jsp?" + m.qs() + "&sid=" + id + "';");
	m.jsReplace("category_all_modify.jsp");
	return;
}

DataSet list = book.find("site_id = " + siteId + " AND status != -1 ORDER BY allsort ASC, id DESC");
while(list.next()) {
	list.put("book_type_conv", m.getItem(list.s("book_type"), book.packageTypes));
	list.put("book_nm_conv", m.cutString(list.s("book_nm"), 60));
	list.put("status_conv", m.getItem(list.s("status"), book.statusList));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), book.displayYn));
	list.put("pub_date_conv", m.time("yyyy.MM.dd", list.s("pub_date")));
	if(!"".equals(list.s("book_img"))) list.put("book_img_url", m.getUploadUrl(list.s("book_img")));
}

//출력
p.setLayout("blank");
p.setBody("book.category_insert");
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