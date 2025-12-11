<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ContentDao content = new ContentDao();
LmCategoryDao category = new LmCategoryDao("course");
LessonDao lesson = new LessonDao();
UserDao user = new UserDao();

//폼체크
f.addElement("s_category_id", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	content.table + " a "	
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
);
lm.setFields("a.*, u.user_nm manager_name, (SELECT count(*) FROM " + lesson.table + " WHERE site_id = "+ siteId +" AND content_id = a.id AND status = 1) lesson_cnt");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id IN (0, " + siteId + ")");
lm.addSearch("a.status", f.get("s_status"));
if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(!"".equals(f.get("s_category_id"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category_id"))) + "' )");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.content_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("content_nm_conv", m.cutString(list.s("content_nm"), 90));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), content.statusList));
	list.put("cate_name", category.getTreeNames(list.s("category_id")));
	list.put("lesson_cnt", list.i("lesson_cnt"));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "강의그룹관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "cate_name=>카테고리명", "content_nm=>콘텐츠명", "manager_name=>담당자명", "description=>설명", "reg_date_conv=>등록일", "status_conv=>상태" }, "강의그룹관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("content.content_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,cid,type,page"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(content.statusList));
p.setLoop("categories", categories);

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.display();

%>