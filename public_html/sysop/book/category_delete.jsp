<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(109, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("book");

//정보
DataSet info = category.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한
if(0 < category.findCount("parent_id = " + id + " AND status = 1")) {
	m.jsError("하위 카테고리가 있습니다.\\n삭제할 수 없습니다.");
	return;
}

//삭제
category.item("status", -1);
if(!category.update("id = " + id + " AND status = 1")) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

category.autoSort(info.i("depth"), info.i("parent_id"), siteId);

m.js("parent.left.location.href = parent.left.location.href;");
m.jsReplace("category_insert.jsp?" + m.qs("id, sid"));

%>