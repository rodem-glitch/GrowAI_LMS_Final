<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(36, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int sid = m.ri("sid");
if(sid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
SurveyDao survey = new SurveyDao();
SurveyQuestionDao question = new SurveyQuestionDao();
SurveyCategoryDao category = new SurveyCategoryDao();
SurveyItemDao surveyItem = new SurveyItemDao();

//추가
if(m.isPost()) {
	if(f.getArr("idx") != null) {

		int maxSort = surveyItem.getOneInt("SELECT MAX(sort) FROM " + surveyItem.table + " WHERE survey_id = " + sid + " AND status = 1 ");
		surveyItem.item("survey_id", sid);
		surveyItem.item("site_id", siteId);
		surveyItem.item("status", 1);
		for(int i = 0; i< f.getArr("idx").length; i++) {
			surveyItem.item("question_id", f.getArr("idx")[i]);
			surveyItem.item("sort", maxSort + i + 1);
			if(!surveyItem.insert()) { }
		}

		//갱신
		survey.updateItemCount(sid);

	}
	out.print("<script>try { parent.opener.location.reload(); } catch(e) { } parent.location.reload();</script>");
	return;
}


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
);
lm.setFields("a.*, b.category_nm");
lm.addWhere("a.status > -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("NOT EXISTS ( SELECT 1 FROM " + surveyItem.table + " WHERE survey_id = " + sid + " AND question_id = a.id )");
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
lm.addSearch("a.category_id", f.get("s_category"));
lm.addSearch("a.question_type", f.get("s_type"));
lm.addSearch("a.status", f.get("s_status"));
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
	list.put("question_conv", m.cutString(list.s("question"), 30));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), question.statusList));
	list.put("type_conv", m.getItem(list.s("question_type"), question.types));
	list.put("item_cnt_conv", list.i("item_cnt") > 1 ? "" + list.i("item_cnt") + "개" : "-");
}

//출력
p.setLayout("pop");
p.setBody("survey.question_select");
p.setVar("p_title", "설문문항 선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setLoop("status_list", m.arr2loop(question.statusList));
p.setLoop("types", m.arr2loop(question.types));
p.setLoop("categories", category.getCategories(siteId));
p.display();

%>