<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ContentDao content = new ContentDao();
CodeDao code = new CodeDao();
CourseCategoryDao category = new CourseCategoryDao();
LessonDao lesson = new LessonDao();

//폼체크
f.addElement("s_status", null, null);
f.addElement("s_category_id", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//카테고리 트리
DataSet tmp = new DataSet();
DataSet tmp2 = category.find("site_id = " + siteinfo.i("id") + " AND status=1", "*", "parent_id ASC, sort ASC");
tmp.addRow(); tmp.put("id", "_r_"); tmp.put("parent_id", "-"); tmp.put("sort", 1); tmp.put("category_nm", "-전체-");
while(tmp2.next()) {
	if("-".equals(tmp2.s("parent_id")))	tmp2.put("parent_id",  "_r_");
	tmp.addRow(tmp2.getRow());
}

//전체를 포함하여 세팅
code.nName = "category_nm";
code.rootNode = "0";
code.setData(tmp);

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	content.table + " a "
	+ " LEFT JOIN " + lesson.table + " l ON a.id = l.content_id AND l.site_id = " + siteId + " AND l.status != -1 "
);
lm.setFields("a.*, COUNT(l.id) lesson_cnt");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId);
lm.addSearch("a.status", f.get("s_status"), "LIKE");
if(!"".equals(m.rs("s_category_id")) && !"_r_".equals(m.rs("s_category_id"))) {
	//하위 카테고리 목록
	lm.addWhere("a.category_id IN (" + m.join(",", code.getChildNodes(m.rs("s_category_id"))) + ")");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.content_nm", f.get("s_keyword"), "LIKE");
}
lm.setGroupBy("l.content_id");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//전체를 제회하고 다시 세팅
code.setData(tmp2);

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("content_nm_conv", m.cutString(list.s("content_nm"), 50));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), content.statusList));
	String cateName = "";
	Object[] pNames = code.getParentNames(list.s("category_id")).toArray();
	for(int i=0; i<pNames.length; i++) cateName = pNames[i] + ("".equals(cateName) ? "" : " > ") + cateName;
	list.put("cate_name", cateName);
}

//전체를 포함하여 세팅
code.setData(tmp);
DataSet categories = code.getTree("0");

while(categories.next()) {
	categories.put("depth_str", m.strpad("", categories.i("depth") - 1, "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"));
}

//출력
p.setLayout("pop");
p.setBody("content.content_select");
p.setVar("p_title", "콘텐츠선택");
p.setVar("list_query", m.qs("id, type"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(content.statusList));
p.setLoop("categories", categories);
p.display();

%>