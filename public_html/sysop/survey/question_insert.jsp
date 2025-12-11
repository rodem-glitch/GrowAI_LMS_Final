<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(35, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SurveyQuestionDao question = new SurveyQuestionDao();
SurveyCategoryDao category = new SurveyCategoryDao();
UserDao user = new UserDao();

//폼체크
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");
f.addElement("question", null, "hname:'문제', required:'Y'");
f.addElement("question_type", "1", "hname:'질문유형', required:'Y'");
f.addElement("item_cnt", 10, "hname:'보기개수', option:'number'");
for(int i = 1; i <= f.getInt("item_cnt"); i++) f.addElement("item" + i, null, "hname:'문항" + i + "', required:'Y'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'");

if(m.isPost() && f.validate()) {
	boolean isFormSingle = "1".equals(f.get("question_type"));
	boolean isFormMulti = "M".equals(f.get("question_type"));
	boolean isFormShort = "2".equals(f.get("question_type"));
	boolean isFormLong = "3".equals(f.get("question_type"));

	boolean isFormChoice = isFormSingle || isFormMulti;
	boolean isFormWrite = isFormShort || isFormLong;

	question.item("site_id", siteId);
	question.item("category_id", f.getInt("category_id"));
	question.item("question", f.get("question"));
	question.item("question_type", f.get("question_type"));
	question.item("item_cnt", isFormChoice ? f.getInt("item_cnt") : 1);
	for(int i = 1; i <= 10; i++) {
		question.item("item" + i, (isFormChoice && f.getInt("item_cnt") >= i) ? f.get("item" + i) : "");
	}
	question.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	question.item("reg_date", m.time("yyyyMMddHHmmss"));
	question.item("status", f.getInt("status"));

	if(!question.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	category.updateItemCnt(f.getInt("category_id"));

	m.jsReplace("question_list.jsp", "parent");
	return;
}

DataSet list = new DataSet();
for(int i = 1; i <= 10; i++) {
	list.addRow();
	list.put("idx", i);
	list.put("options", i != 1);
}

//출력
p.setBody("survey.question_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);

p.setLoop("types", m.arr2loop(question.types));
p.setLoop("status_list", m.arr2loop(question.statusList));
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>