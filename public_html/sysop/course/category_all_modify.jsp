<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(22, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("course");
CourseDao course = new CourseDao();

int id = siteId * -1;

String[] idx = m.reqArr("idx");
if(idx != null && idx.length > 0) {
	for(int i = 0; i < idx.length; i++) {
		course.item("allsort", i);
		course.update("id = " + idx[i]);
	}
	
	category.item("sort_type", "st asc");
	if(!category.update("id = " + id + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	m.redirect("category_all_modify.jsp");
	return;
}

//정보
DataSet info = category.find("id = " + id + " AND status = 1 AND site_id = " + siteId + " AND module = 'course'");
if(!info.next()) {
	category.item("id", id);
	category.item("site_id", siteId);
	category.item("module", "course");
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

DataSet list = course.find("site_id = " + siteId + " AND status != -1 AND close_yn = 'N' ORDER BY allsort ASC, request_edate DESC, reg_date DESC, id DESC");
while(list.next()) {
	list.put("regular_block", "R".equals(list.s("course_type")));
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 40));
	list.put("status_conv", m.getItem(list.s("status"), course.statusList));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), course.displayYn));
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));
	if("A".equals(list.s("course_type"))) {
		list.put("request_date", "상시");
	} else {
		list.put("request_date", m.time("yyyy.MM.dd", list.s("request_sdate")) + "  ~ " + m.time("yyyy.MM.dd", list.s("request_edate")));
	}
}

//출력
p.setLayout("blank");
p.setBody("course.category_insert");
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