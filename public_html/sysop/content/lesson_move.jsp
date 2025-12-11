<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String id = m.rs("idx");
int cid = m.ri("cid");
if("".equals(id) || 0 == cid) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
ContentDao content = new ContentDao();
LmCategoryDao category = new LmCategoryDao("course");
LessonDao lesson = new LessonDao();
UserDao user = new UserDao();

//이동
if(m.isPost()) {
	//변수
	int success = 0;
	if(f.getInt("content_id") == 0) { m.jsErrClose("콘텐츠키는 반드시 지정해야 합니다."); return; }

	//목록
	DataSet list = lesson.find("id IN (" + id + ") AND content_id = " + cid + " AND site_id = " + siteId + " AND status != -1");
	while(list.next()) {
		lesson.item("content_id", f.getInt("content_id"));
		lesson.item("sort", lesson.getMaxSort(f.getInt("content_id"), list.s("use_yn"), siteId));
		if(lesson.update("id = " + list.s("id"))) { success++; }
	}
	
	//순서
	lesson.autoSort(cid, siteId);
	lesson.autoSort(f.getInt("content_id"), siteId);

	m.jsAlert("총 " + list.size() + "개의 강의 중 " + success + "개를 이동했습니다.");
	m.js("parent.opener.location.reload();");
	m.js("parent.window.close();");
	return;
}

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
	+ " LEFT JOIN " + lesson.table + " l ON a.id = l.content_id AND l.site_id = " + siteId + " AND l.status != -1 "
);
lm.setFields("a.*, u.user_nm manager_name, COUNT(l.id) lesson_cnt");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId);
lm.addWhere("a.id != " + cid);
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_category_id"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category_id"))) + "' )");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.content_nm", f.get("s_keyword"), "LIKE");
}
lm.setGroupBy("l.content_id, a.id");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("content_nm_conv", m.cutString(list.s("content_nm"), 50));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), content.statusList));
	list.put("cate_name", category.getTreeNames(list.s("category_id")));
	list.put("lesson_cnt", list.i("lesson_cnt"));
}

//출력
p.setLayout("pop");
p.setBody("content.lesson_move");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,type"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(content.statusList));
p.setLoop("categories", categories);

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.display();

%>