<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!Menu.accessible(74, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ForumDao forum = new ForumDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();

//폼체크
f.addElement("onoff_type", "N", "hname:'구분', required:'Y'");
f.addElement("category_id", null, "hname:'카테고리명'");
f.addElement("forum_nm", null, "hname:'토론명', required:'Y'");
f.addElement("content", null, "hname:'내용'");
f.addElement("forum_file", null, "hname:'첨부파일'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int newId = forum.getSequence();

	forum.item("id", newId);
	forum.item("site_id", siteId);
	forum.item("onoff_type", f.get("onoff_type", "N"));
	forum.item("category_id", f.get("category_id"));
	forum.item("forum_nm", f.get("forum_nm"));
	forum.item("content", f.get("content"));
	forum.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	forum.item("reg_date", m.time("yyyyMMddHHmmss"));
	forum.item("status", f.getInt("status"));

	if(null != f.getFileName("forum_file")) {
		File f1 = f.saveFile("forum_file");
		if(f1 != null) forum.item("forum_file", f.getFileName("forum_file"));
	}

	if(!forum.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("forum_list.jsp", "parent");
	return;

}

//출력
p.setBody("forum.forum_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(forum.statusList));
p.setLoop("onoff_types", m.arr2loop(forum.onoffTypes));
p.setLoop("categories", category.getList(siteId));
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>