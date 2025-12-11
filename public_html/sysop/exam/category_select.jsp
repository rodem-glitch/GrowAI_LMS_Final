<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(72, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
int eid = m.ri("eid");
if(eid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//객체
ExamDao exam = new ExamDao();
QuestionCategoryDao category = new QuestionCategoryDao();

//정보
String[] rangeArr = null;
DataSet info = exam.find("id = " + eid + " AND status != -1 AND site_id = " + siteId + "");
if(info.next()) {
	rangeArr = !"".equals(info.s("range_idx")) ? info.s("range_idx").split(",") : null;
}


//목록
DataSet list = category.getList(siteId);
while(list.next()) {
	list.put("disabled", m.inArray(list.s("category_id"), rangeArr));
	list.put("display_block", list.i("manager_id") == -99 || !courseManagerBlock || (courseManagerBlock && list.i("manager_id") == userId));
}

//출력
p.setLayout("pop");
p.setBody("exam.category_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.display();

%>