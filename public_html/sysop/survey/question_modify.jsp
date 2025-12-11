<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(35, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SurveyQuestionDao question = new SurveyQuestionDao();
SurveyCategoryDao category = new SurveyCategoryDao();
UserDao user = new UserDao();

//정보
DataSet info = question.query(
	"SELECT a.*, b.category_nm, u.user_nm manager_name "
	+ " FROM " + question.table + " a "
	+ " LEFT JOIN " + category.table + " b ON a.category_id = b.id "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1"
);
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

//변수
boolean isSingle = "1".equals(info.s("question_type"));
boolean isMulti = "M".equals(info.s("question_type"));
boolean isShort = "2".equals(info.s("question_type"));
boolean isLong = "3".equals(info.s("question_type"));

boolean isChoice = isSingle || isMulti;
boolean isWrite = isShort || isLong;

//폼체크
f.addElement("category_id", info.s("category_id"), "hname:'카테고리', required:'Y'");
f.addElement("category_nm", info.s("category_nm"), "hname:'카테고리', required:'Y'");
f.addElement("question", info.s("question"), "hname:'문제', required:'Y'");
f.addElement("question_type", info.s("question_type"), "hname:'질문유형', required:'Y'");
f.addElement("item_cnt", info.i("item_cnt"), "hname:'보기개수', option:'number'");
if(m.ri("item_cnt", info.i("item_cnt")) > 1) {
	for(int i = 1; i <= m.ri("item_cnt", info.i("item_cnt")); i++) {
		f.addElement("item" + i, info.s("item" + i), "hname:'문항" + i + "', required:'Y'");
	}
}
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
if(!courseManagerBlock) f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'상태', option:'number', required:'Y'");

//수정
if(m.isPost() && f.validate()) {
	boolean isFormSingle = "1".equals(f.get("question_type"));
	boolean isFormMulti = "M".equals(f.get("question_type"));
	boolean isFormShort = "2".equals(f.get("question_type"));
	boolean isFormLong = "3".equals(f.get("question_type"));

	boolean isFormChoice = isFormSingle || isFormMulti;
	boolean isFormWrite = isFormShort || isFormLong;

	question.item("category_id", f.getInt("category_id"));
	question.item("question", f.get("question"));
	question.item("question_type", f.get("question_type"));
	question.item("item_cnt", isFormChoice ? f.getInt("item_cnt") : 1);
	for(int i = 1; i <= 10; i++) {
		question.item("item" + i, (isFormChoice && f.getInt("item_cnt") >= i) ? f.get("item" + i) : "");
	}
	if(!courseManagerBlock) question.item("manager_id", f.getInt("manager_id"));
	question.item("status", f.getInt("status"));

	if(!question.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//갱신
	category.updateItemCnt(f.getInt("category_id"));

	m.jsReplace("question_list.jsp?" + m.qs("id"), "parent");
	return;
}

DataSet list = new DataSet();
for(int i=1; i<=10; i++) {
	list.addRow();
	list.put("idx", i);
	list.put("options", i != 1);
}

//출력
p.setBody("survey.question_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setLoop("list", list);

p.setLoop("status_list", m.arr2loop(question.statusList));
p.setLoop("types", m.arr2loop(question.types));
p.setLoop("managers", user.getManagers(siteId));

p.display();

%>