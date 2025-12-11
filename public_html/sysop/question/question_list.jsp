<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(32, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
QuestionDao question = new QuestionDao();
QuestionCategoryDao category = new QuestionCategoryDao();
UserDao user = new UserDao();

//처리
if("status".equals(m.rs("mode"))) {

	String[] idx = f.getArr("idx");
	if(idx.length == 0) { return; }

	if(-1 == question.execute(
			"UPDATE " + question.table + " SET "
					+ " status = " + f.get("a_status") + " "
					+ " WHERE id IN (" + m.join(",", idx) + ") AND site_id = " + siteId
	)) {
		m.jsError("변경처리하는 중 오류가 발생했습니다."); return;
	}

	m.js("parent.location.href = parent.location.href");
	return;
}

//폼체크
f.addElement("s_category", null, null);
f.addElement("s_grade", null, null);
f.addElement("s_type", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록-카테고리
DataSet categories = category.getList(siteId);
while(categories.next()) {
	categories.put("display_block", categories.i("manager_id") == -99 || !courseManagerBlock || (courseManagerBlock && categories.i("manager_id") == userId));
}

//카테고리
//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 10);
lm.setTable(
		question.table + " a "
				+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
				+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
);
lm.setFields("a.*, c.category_nm, u.user_nm manager_nm, u.login_id");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");

if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ('" + m.join("','", category.getChildNodes(f.get("s_category"), categories)) + "')");
}
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
lm.addSearch("a.grade", f.get("s_grade"));
lm.addSearch("a.question_type", f.get("s_type"));
lm.addSearch("a.status", f.get("s_status"));
//if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(!"".equals(f.get("s_keyword"))) {
	if(!"".equals(f.get("s_field"))) {
		if("a.question_item".equals(f.get("s_field"))) {
			lm.addSearch("a.item1,a.item2,a.item3,a.item4,a.item5", f.get("s_keyword"), "LIKE");
		} else { lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE"); }
	} else {
		lm.addSearch("a.question,a.question_text,a.item1,a.item2,a.item3,a.item4,a.item5", f.get("s_keyword"), "LIKE");
	}
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("question_type_conv", m.getItem(list.s("question_type"), question.types));
	list.put("grade_conv", m.getItem(list.s("grade"), question.grades));
	list.put("question_conv", m.cutString(m.htmlToText(list.s("question")), 100));
	list.put("status_conv", m.getItem(list.s("status"), question.statusList));
	list.put("status_color", list.i("status") == 1 ? "blue" : "gray");
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	//list.put("cate_name", category.getTreeNames(list.s("category_id")));
	list.put("cate_name", list.s("category_nm"));

	list.put("manager_block", 0 < list.i("manager_id"));
	if(-99 == list.i("manager_id")) list.put("manager_nm_conv", "공용");
	else if(1 > list.i("manager_id")) list.put("manager_nm_conv", "없음");
	else list.put("manager_nm_conv", list.s("manager_nm"));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "문제은행(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "category_nm=>카테고리명", "grade_conv=>난이도", "question_type_conv=>문제유형", "question=>문제", "question_text=>문제지문", "item_cnt=>보기 갯 수", "item1=>보기1", "item1_file=>보기1 파일", "item2=>보기2", "item2_file=>보기2 파일", "item3=>보기3", "item3_file=>보기3 파일", "item4=>보기4", "item4_file=>보기4 파일", "item5=>보기5", "item5_file=>보기5 파일", "answer=>정답", "description=>설명", "reg_date_conv=>등록일", "status_conv=>상태" }, "문제은행(" + m.time("yyyy-MM-dd"));
	ex.write();
	return;
}

//출력
p.setLayout(ch);
p.setBody("question.question_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,idx"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("categories", categories);
p.setLoop("types", m.arr2loop(question.types));
p.setLoop("grades", m.arr2loop(question.grades));
p.setLoop("status_list", m.arr2loop(question.statusList));
p.display();

%>