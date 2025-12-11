<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(35, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SurveyQuestionDao question = new SurveyQuestionDao();
SurveyCategoryDao category = new SurveyCategoryDao();
UserDao user = new UserDao();

//폼체크
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);

f.addElement("s_category", null, null);
f.addElement("s_type", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	question.table + " a "
	+ " LEFT JOIN " + category.table + " b ON a.category_id = b.id"
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
);
lm.setFields("a.*, b.category_nm, u.user_nm manager_nm, u.login_id");
lm.addWhere("a.status > -1");
lm.addWhere("a.site_id = " + siteId + "");
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
lm.addSearch("a.category_id", f.get("s_category"));
lm.addSearch("a.question_type", f.get("s_type"));
lm.addSearch("a.status", f.get("s_status"));
//if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(!"".equals(f.get("s_sdate"))) lm.addSearch("a.reg_date", m.time("yyyyMMdd000000", f.get("s_sdate")), ">=");
if(!"".equals(f.get("s_edate"))) lm.addSearch("a.reg_date", m.time("yyyyMMdd235900", f.get("s_edate")), "<=");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.question", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("question_conv", m.cutString(list.s("question"), 100));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), question.statusList));
	list.put("type_conv", m.getItem(list.s("question_type"), question.types));
	list.put("item_cnt_conv", list.i("item_cnt") > 1 ? list.s("item_cnt") + "개" : "-");

	list.put("manager_block", 0 < list.i("manager_id"));
	if(-99 == list.i("manager_id")) list.put("manager_nm_conv", "공용");
	else if(1 > list.i("manager_id")) list.put("manager_nm_conv", "없음");
	else list.put("manager_nm_conv", list.s("manager_nm"));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "설문문항관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "category_nm=>카테고리", "type_conv=>질문타입", "question=>질문", "item_cnt_conv=>보기개수", "item1=>보기1", "item2=>보기2", "item3=>보기3", "item4=>보기4", "item5=>보기5", "item6=>보기6", "item7=>보기7", "item8=>보기8", "item9=>보기9", "item10=>보기10", "reg_date=>등록일", "status_conv=>상태" }, "설문문항관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("survey.question_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(question.statusList));
p.setLoop("types", m.arr2loop(question.types));
p.setLoop("categories", category.getCategories(siteId));
p.display();

%>