<%@ page import="javax.sql.DataSource" %>
<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(91, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(1 > id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
MainpageDao mainpage = new MainpageDao();

//정보
DataSet info = mainpage.find("id = ? AND site_id = ? AND status != -1", new Integer[] {id, siteId});
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
mainpage.item("status", -1);
if(!mainpage.update("id = " + id)) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}
mainpage.clear();

//수정
DataSet list = mainpage.find("site_id = " + siteId + " AND status != -1", "id, sort", "sort ASC");
int sort = 1;
while(list.next()) {
	mainpage.item("sort", sort++);
	mainpage.update("id = " + list.s("id"));
}

//이동
m.jsReplace("mainpage_list.jsp?" + m.qs("id"), "parent");

%>