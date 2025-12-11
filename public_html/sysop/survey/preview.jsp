<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(36, userId, userKind) && !Menu.accessible(33, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//폼입력
String idx = m.rs("idx");
int id = m.ri("id");

//객체
SurveyDao survey = new SurveyDao();
SurveyQuestionDao question = new SurveyQuestionDao();
SurveyItemDao surveyItem = new SurveyItemDao();
SurveyCategoryDao category = new SurveyCategoryDao();

//목록
DataSet list = new DataSet();
if(!"".equals(idx)) {

	String[] idxArr = idx.split(",");

	String caseStr = "CASE ";
	for(int i=0, max=idxArr.length; i<max; i++) caseStr += " WHEN a.id = " + idxArr[i] + " THEN " + i;
	caseStr += " ELSE 9999 END";

	list = question.query(
		"SELECT a.*, b.category_nm "
		+ ", (" + caseStr + ") sort "
		+ " FROM " + question.table + " a "
		+ " LEFT JOIN " + category.table + " b ON a.category_id = b.id "
		+ " WHERE a.id IN (" + idx + ") AND a.status = 1 "
		+ " ORDER BY sort ASC "
	);

} else if(id != 0) {
	list = surveyItem.query(
		"SELECT b.*, c.category_nm "
		+ " FROM " + surveyItem.table + " a "
		+ " INNER JOIN " + question.table + " b ON a.question_id = b.id AND b.status = 1"
		+ " LEFT JOIN " + category.table + " c ON b.category_id = c.id "
		+ " WHERE a.status = 1 AND a.survey_id = " + id + " "
		+ " ORDER BY a.sort ASC "
	);
} else { m.jsErrClose("기본키는 반드시 있어야 합니다."); return; }

while(list.next()) {
	list.put("choice_block", "1".equals(list.s("question_type")) || "M".equals(list.s("question_type")));
	list.put("textarea_block", "3".equals(list.s("question_type")));
	list.put("input_type", "1".equals(list.s("question_type")) ? "radio" : ("M".equals(list.s("question_type")) ? "checkbox" : "text"));

	DataSet answers = new DataSet();
	for(int i=1; i<=list.i("item_cnt"); i++) {
		answers.addRow();
		answers.put("id", i);
		answers.put("name", list.s("item" + i));
	}
	list.put(".subLoop", answers);
	list.put("type_conv", m.getItem(list.s("question_type"), question.types));
}

//출력
p.setLayout("pop");
p.setBody("survey.preview");
p.setVar("p_title", "설문 미리보기");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.display();
%>