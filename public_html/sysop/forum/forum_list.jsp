<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(74, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ForumDao forum = new ForumDao();
LmCategoryDao category = new LmCategoryDao();
CourseModuleDao courseModule = new CourseModuleDao();
UserDao user = new UserDao();

//카테고리
DataSet categories = category.getList(siteId);

//폼체크
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);

f.addElement("s_category", null, null);
f.addElement("s_status", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	forum.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
);
lm.setFields(
	" a.*, u.user_nm manager_nm, u.login_id "
	+ " , (SELECT COUNT(*) FROM " + courseModule.table + " WHERE module = 'forum' AND module_id = a.id) cnt "
);
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.category_id", f.get("s_category_id"));
lm.addSearch("a.onoff_type", f.get("s_onofftype"));
lm.addSearch("a.reg_date", m.time("yyyyMMdd000000", f.get("s_sdate")), ">=");
lm.addSearch("a.reg_date", m.time("yyyyMMdd235959", f.get("s_edate")), "<=");
//if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.forum_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("forum_nm_conv", m.cutString(list.s("forum_nm"), 90));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), forum.statusList));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), forum.onoffTypes));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));

	list.put("manager_block", 0 < list.i("manager_id"));
	if(-99 == list.i("manager_id")) list.put("manager_nm_conv", "공용");
	else if(1 > list.i("manager_id")) list.put("manager_nm_conv", "없음");
	else list.put("manager_nm_conv", list.s("manager_nm"));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "토론관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "forum_nm=>토론명", "forum_file=>토론파일", "content=>내용", "reg_date_conv=>등록일", "status_conv=>상태" }, "토론관리 (" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("forum.forum_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("categories", categories);
p.setLoop("status_list", m.arr2loop(forum.statusList));
p.setLoop("onoff_types", m.arr2loop(forum.onoffTypes));
p.display();

%>