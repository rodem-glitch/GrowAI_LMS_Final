<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(71, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
QuestionCategoryDao category = new QuestionCategoryDao();
QuestionDao question = new QuestionDao();

//정보
DataSet info = category.find("id = " + id + " AND status = 1 AND site_id = " + siteId + (courseManagerBlock ? " AND manager_id IN (-99, " + userId + ")" : ""));
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한-과정운영자
if(courseManagerBlock && -99 == info.i("manager_id")) {
	m.jsError("과정운영자는 공용 자료를 삭제할 수 없습니다."); return;
}

//제한
if(0 < category.findCount("parent_id = " + id + " AND status = 1")) {
	m.jsError("하위 카테고리가 있습니다.\\n삭제할 수 없습니다.");
	return;
}

//제한-문제은행
if(0 < question.findCount("category_id = " + id + " AND status != -1")) {
	m.jsError("해당 카테고리는 문제은행에서 사용중입니다. 삭제할 수 없습니다."); return;
}

//삭제
if(!category.delete("id = " + id + " AND status = 1")) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

category.autoSort(info.i("depth"), info.i("parent_id"), siteId);

m.js("parent.left.location.href = parent.left.location.href;");
m.jsReplace("category_insert.jsp?" + m.qs("id, sid"));

%>