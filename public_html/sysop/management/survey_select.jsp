<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SurveyDao survey = new SurveyDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseModuleDao courseModule = new CourseModuleDao();

//처리
if("add".equals(m.rs("mode"))) {
	//기본키
	int id = m.ri("id");
	if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet info = survey.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

	//제한
	if(0 < courseModule.findCount("course_id = " + courseId + " AND module = 'survey' AND module_id = " + id + " AND status != -1")) {
		m.jsAlert("해당 설문은 이미 배정되어 있습니다.");
		m.js("opener.location.href = opener.location.href; window.close();");
		return;
	}

	String applyType = "R".equals(cinfo.s("course_type")) ? "1" : "2";
	int chapter = "R".equals(cinfo.s("course_type")) ? 1 : 0;
	/*
	int totalAssignScore = courseModule.getOneInt(
		"SELECT SUM(assign_score) FROM " + courseModule.table + " "
		+ " WHERE course_id = " + courseId + " AND module = 'survey' AND status = 1 "
	);
	int assignScore = cinfo.i("assign_survey") - totalAssignScore;
	if(assignScore < 0) assignScore = 0;
	*/

	//추가
	courseModule.item("course_id", courseId);
	courseModule.item("site_id", siteId);
	courseModule.item("module", "survey");
	courseModule.item("module_id", id);
	courseModule.item("module_nm", info.s("survey_nm"));
	courseModule.item("parent_id", 0);
	courseModule.item("item_type", "1");
	courseModule.item("assign_score", 0);
	courseModule.item("apply_type", applyType);
	courseModule.item("start_day", 0);
	courseModule.item("period", 0);
	courseModule.item("chapter", chapter);
	courseModule.item("start_date", "");
	courseModule.item("end_date", "");
	if("1".equals(applyType)) {
		courseModule.item("start_date", cinfo.s("study_sdate") + "000000");
		courseModule.item("end_date", cinfo.s("study_edate") + "000000");
	}
	courseModule.item("status", 1);
	if(!courseModule.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("추가되었습니다.");
	m.js("opener.location.href = opener.location.href; window.close();");
	return;
}


//카테고리
DataSet categories = category.getList(siteId);

//폼체크
f.addElement("s_category", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(survey.table + " a ");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("NOT EXISTS ( "
	+ " SELECT 1 FROM " + courseModule.table + " "
	+ " WHERE course_id = " + courseId + " AND module = 'survey' AND module_id = a.id "
+ " )");
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.survey_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("survey_nm_conv", m.cutString(list.s("survey_nm"), 40));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), survey.statusList));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
}


//출력
p.setLayout("pop");
p.setBody("management.survey_select");
p.setVar("p_title", "설문 추가");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("course", cinfo);
p.setLoop("categories", categories);
p.display();

%>