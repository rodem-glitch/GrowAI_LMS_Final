<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(36, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SurveyDao survey = new SurveyDao();
SurveyItemDao surveyItem = new SurveyItemDao();
LmCategoryDao category = new LmCategoryDao("course");
UserDao user = new UserDao();

//목록-카테고리
DataSet categories = category.getList(siteId);
if(1 > categories.size()) { m.jsError("등록된 과정카테고리가 없습니다.\\n설문지를 등록하시려면 먼저 과정카테고리를 등록해주세요."); return; }

//폼체크
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");
f.addElement("survey_nm", null, "hname:'설문제목', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'");

if(m.isPost() && f.validate()) {

	int newId = survey.getSequence();
	survey.item("id", newId);
	survey.item("site_id", siteId);
	survey.item("category_id", f.get("category_id"));
	survey.item("survey_nm", f.get("survey_nm"));
	survey.item("content", f.get("content"));
	survey.item("item_cnt", f.getArr("question_id") != null ? f.getArr("question_id").length : 0);
	survey.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	survey.item("reg_date", m.time("yyyyMMddHHmmss"));
	survey.item("status", f.getInt("status"));

	if(!survey.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	if(f.getArr("question_id") != null) {
		surveyItem.item("survey_id", newId);
		surveyItem.item("site_id", siteId);
		surveyItem.item("post_yn", "N");
		surveyItem.item("status", 1);
		for(int i = 0; i < f.getArr("question_id").length; i++) {
			surveyItem.item("question_id", f.getArr("question_id")[i]);
			surveyItem.item("sort", i + 1);

			if(!surveyItem.insert()) { }
		}
	}

	m.jsReplace("survey_list.jsp", "parent");
	return;
}

//출력
p.setBody("survey.survey_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(survey.statusList));
p.setLoop("categories", categories);
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>