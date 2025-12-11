<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//객체
LibraryDao library = new LibraryDao();
CourseLibraryDao courseLibrary = new CourseLibraryDao();
LmCategoryDao category = new LmCategoryDao();


//처리
if("add".equals(m.rs("mode"))) {
	String[] idx = f.get("idx").split(",");

	courseLibrary.item("course_id", courseId);
	courseLibrary.item("site_id", siteId);
	for(int i = 0; i < idx.length; i++) {
		courseLibrary.item("library_id", idx[i]);
		if(!courseLibrary.insert()) { }
	}

	m.js("parent.opener.location.href = parent.opener.location.href; parent.window.close();");
	return;
}

//폼입력
String subjectId = f.get("s_category", cinfo.s("category_id"));

//폼체크
f.addElement("s_category", subjectId, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	library.table + " a "
	
);
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("NOT EXISTS (SELECT 1 FROM " + courseLibrary.table + " WHERE course_id = " + courseId + " AND library_id = a.id)");
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
lm.addSearch("a.category_id", subjectId);
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.library_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("library_nm_conv", m.cutString(list.s("library_nm"), 90));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), library.statusList));
}


//출력
p.setLayout("pop");
p.setBody("management.library_select");
p.setVar("p_title", "자료추가");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("mode_query", m.qs("mode,idx"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("categories", category.getList(siteId));
p.setLoop("status_list", m.arr2loop(library.statusList));
p.display();

%>