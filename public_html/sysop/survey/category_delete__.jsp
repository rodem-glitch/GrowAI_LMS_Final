<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(35, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//유효성검사
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다"); return; }

//객체
SurveyCategoryDao category = new SurveyCategoryDao();

DataSet info = category.find("site_id = " + siteinfo.i("id") + " AND id = " + id + " AND status = 1");
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

category.item("status", -1);

if(!category.update("id = " + id + " AND status = 1")) {
	m.jsError("삭제하는 중 오류가 발생했습니다."); return;
}

m.jsReplace("pop_category.jsp?" + m.qs("id"));

%>