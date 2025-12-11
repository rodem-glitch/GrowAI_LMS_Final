<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

if(!(Menu.accessible(123, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//폼체크
f.addElement("s_open_sdate", null, null);
f.addElement("s_open_edate", null, null);
f.addElement("s_category", null, null);
f.addElement("s_display_yn", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//객체
WebtvDao webtv = new WebtvDao();
WebtvLogDao webtvLog = new WebtvLogDao();
WebtvRecommDao webtvRecomm = new WebtvRecommDao();
LessonDao lesson = new LessonDao();
LmCategoryDao category = new LmCategoryDao("webtv");

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 1000000 : f.getInt("s_listnum", 20));
lm.setTable(
	webtv.table + " a "
	+ " LEFT JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.site_id = " + siteId);
lm.setFields(
	"a.*, l.lesson_nm"
	+ ", (SELECT COUNT(*) FROM " + webtvLog.table + " WHERE webtv_id = a.id) hit_cnt"
	+ ", (SELECT COUNT(*) FROM " + webtvRecomm.table + " WHERE webtv_id = a.id) recomm_cnt"
);
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");

if(!"".equals(f.get("s_open_sdate"))) lm.addWhere("a.open_date >= '" + m.time("yyyyMMdd000000", f.get("s_open_sdate")) + "'");
if(!"".equals(f.get("s_open_edate"))) lm.addWhere("a.open_date <= '" + m.time("yyyyMMdd235959", f.get("s_open_edate")) + "'");
if(!"".equals(f.get("s_category"))) lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
lm.addSearch("a.display_yn", f.get("s_display_yn"));
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.year", f.get("s_year"));
lm.addSearch("a.grade", f.get("s_grade"));
lm.addSearch("a.term", f.get("s_term"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.webtv_nm, a.subtitle, a.keywords, a.content, l.lesson_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("category_nm", category.getTreeNames(list.i("category_id")));
	list.put("webtv_nm_conv", m.cutString(list.s("webtv_nm"), 50));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 50));
	list.put("subtitle_conv", m.stripTags(list.s("subtitle")));
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), webtv.displayList));
	list.put("status_conv", m.getItem(list.s("status"), webtv.statusList));

	list.put("hit_cnt_conv", m.nf(list.i("hit_cnt")));
	list.put("recomm_cnt_conv", m.nf(list.i("recomm_cnt")));
	list.put("open_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("open_date")));
	list.put("end_date_conv", list.b("end_yn") ? m.time("yyyy.MM.dd", list.s("end_date")) : "-");
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));

	list.put("grade_conv", Malgn.getItem(list.s("grade"), webtv.grades));
	list.put("term_conv", Malgn.getItem(list.s("term"), webtv.terms));
	list.put("subject_conv", Malgn.getItem(list.s("subject"), webtv.subjects));
}


//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "방송관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "category_id=>카테고리ID", "category_nm=>카테고리", "webtv_nm=>방송제목", "lesson_id=>강의ID", "lesson_nm=>강의", "subtitle=>부제목", "open_date_conv=>방송일시", "reg_date_conv=>등록일", "status_conv=>상태" }, "방송관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("webtv.webtv_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(webtv.statusList));
p.setLoop("display_list", m.arr2loop(webtv.displayList));
p.setLoop("categories", categories);

p.setLoop("grades", m.arr2loop(webtv.grades));
p.setLoop("terms", m.arr2loop(webtv.terms));
p.setLoop("subjects", m.arr2loop(webtv.subjects));

p.display();

%>