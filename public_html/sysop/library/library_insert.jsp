<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(77, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LibraryDao library = new LibraryDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();

//폼체크
f.addElement("category_id", null, "hname:'카테고리명'");
f.addElement("library_nm", null, "hname:'자료명', required:'Y'");
f.addElement("content", null, "hname:'자료설명'");
f.addElement("library_file", null, "hname:'자료파일', required:'Y'");
f.addElement("library_link", null, "hname:'자료링크'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int newId = library.getSequence();

	library.item("id", newId);
	library.item("site_id", siteId);
	library.item("category_id", f.get("category_id"));
	library.item("library_nm", f.get("library_nm"));
	library.item("content", f.get("content"));
	library.item("library_link", f.get("library_link"));

	if(null != f.getFileName("library_file")) {
		File f1 = f.saveFile("library_file");
		if(f1 != null) library.item("library_file", f.getFileName("library_file"));
	}
	library.item("download_cnt", 0);
	library.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	library.item("reg_date", m.time("yyyyMMddHHmmss"));
	library.item("status", f.get("status"));

	if(!library.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("library_list.jsp", "parent");
	return;
}


//출력
p.setBody("library.library_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(library.statusList));
p.setLoop("categories", category.getList(siteId));
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>