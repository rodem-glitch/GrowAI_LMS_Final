<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(38, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
BookDao book = new BookDao();
CourseBookDao courseBook = new CourseBookDao();

//정보
DataSet info = book.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다.");	return; }

//제한-모듈
if(0 < courseBook.findCount("book_id = " + id + "")) {
	m.jsError("해당 도서는 개설된 과정에서 사용중입니다. 삭제할 수 없습니다.");
	return;
}

//삭제
book.item("status", -1);
if(!book.update("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

m.jsReplace("book_list.jsp?" + m.qs("id"));

%>