<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

String cid = m.rs("cid");
if("".equals(cid)) { m.jsErrClose("기본키는 반드시 있어야 합니다."); return; }

//객체
SurveyDao survey = new SurveyDao();
CourseSurveyDao courseSurvey = new CourseSurveyDao();

//폼객체
f.addElement("s_sreg_date", null, null);
f.addElement("s_ereg_date", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(survey.table + " a ");
lm.setFields("a.*");
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
//if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(!"".equals(f.get("s_sdate"))) lm.addSearch("a.reg_date", m.time("yyyyMMdd000000", f.get("s_sdate")), ">=");
if(!"".equals(f.get("s_edate"))) lm.addSearch("a.reg_date", m.time("yyyyMMdd235959", f.get("s_edate")), "<=");
lm.addWhere("a.site_id = " + siteinfo.i("id") + " AND a.status = 1");
lm.addWhere("NOT EXISTS (SELECT survey_id FROM " + courseSurvey.table + " WHERE survey_id = a.id AND course_id = " + cid + ")");

if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.survey_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("name_conv", m.cutString(list.s("survey_nm"), 40));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), survey.statusList));
}

//출력
p.setLayout("pop");
p.setVar("p_title", "설문선택");
p.setBody("survey.survey_select");
p.setVar("list_query", m.getQueryString("id"));
p.setVar("query", m.getQueryString());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.display();

%>