<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(36, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SurveyDao survey = new SurveyDao();
SurveyQuestionDao question = new SurveyQuestionDao();
SurveyItemDao surveyItem = new SurveyItemDao();
SurveyCategoryDao surveyCategory = new SurveyCategoryDao();
LmCategoryDao category = new LmCategoryDao("course");
UserDao user = new UserDao();
CourseModuleDao courseModule = new CourseModuleDao();

//정보
DataSet info = survey.query(
	"SELECT a.*, u.user_nm manager_name "
	+ " FROM " + survey.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//카테고리
DataSet categories = category.getList(siteId);

//폼체크
f.addElement("category_id", info.s("category_id"), "hname:'카테고리'");
f.addElement("category_nm", category.getTreeNames(info.i("category_id")), "hname:'카테고리'");
f.addElement("survey_nm", info.s("survey_nm"), "hname:'설문제목', required:'Y'");
f.addElement("content", null, "hname:'설명', allowhtml:'Y'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
if(!courseManagerBlock) f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y', option:'number'");

//수정
if(m.isPost() && f.validate()) {

	survey.item("category_id", f.getInt("category_id"));
	survey.item("survey_nm", f.get("survey_nm"));
	survey.item("content", f.get("content"));
	survey.item("item_cnt", f.getArr("question_id") != null ? f.getArr("question_id").length : 0);
	if(!courseManagerBlock) survey.item("manager_id", f.getInt("manager_id"));
	survey.item("status", f.getInt("status"));

	if(!survey.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//삭제
	surveyItem.delete("survey_id = " + id + "");

	//등록
	if(f.getArr("question_id") != null) {
		surveyItem.item("site_id", siteId);
		surveyItem.item("survey_id", id);
		surveyItem.item("status", 1);

		for(int i = 0; i < f.getArr("question_id").length; i++) {
			surveyItem.item("question_id", f.getArr("question_id")[i]);
			surveyItem.item("sort", m.parseInt(f.getArr("sort")[i]));
			if(!surveyItem.insert()) { }
		}
		surveyItem.autoSort(siteId, info.i("id"));
	}

	//수정
	if(!info.s("survey_nm").equals(f.get("survey_nm"))) {
		courseModule.item("module_nm", f.get("survey_nm"));
		if(!courseModule.update("site_id = " + siteId + " AND module = 'survey' AND module_id = " + id)) {
			m.jsAlert("기존 설문명을 수정하는 중 오류가 발생했습니다.");
			return;
		}
	}

	m.jsReplace("survey_modify.jsp?" + m.qs(), "parent");
	return;
}

//포멧팅
info.put("reg_date", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));

//목록-문항
DataSet questions = surveyItem.query(
	"SELECT a.*, q.question, q.question_type, c.category_nm "
	+ " FROM " + surveyItem.table + " a "
	+ " INNER JOIN " + question.table + " q ON a.question_id = q.id "
	+ " LEFT JOIN " + surveyCategory.table + " c ON q.category_id = c.id "
	+ " WHERE a.survey_id = " + id + " AND a.status != -1 "
	+ " ORDER BY a.sort ASC "
);
while(questions.next()) {
	questions.put("type_conv", m.getItem(questions.s("question_type"), question.types));
}

//m.p(questions);

//출력
p.setBody("survey.survey_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
//courseModule.d(out);
p.setLoop("status_list", m.arr2loop(survey.statusList));
p.setLoop("questions", questions);
p.setLoop("managers", user.getManagers(siteId));
p.setLoop("courses", courseModule.getCourses("survey", id, userKind, manageCourses));
p.setVar("course_cnt", courseModule.getCourseCount("survey", id, userKind, manageCourses));
p.setLoop("categories", category.getList(siteId));
p.display();

%>