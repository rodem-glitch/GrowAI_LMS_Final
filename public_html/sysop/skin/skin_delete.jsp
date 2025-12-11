<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(10, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SiteSkinDao siteSkin = new SiteSkinDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = siteSkin.find("id = '" + id + "'");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
if(!siteSkin.delete("id = '" + m.rs("id") + "'")) {
	m.jsError("삭제하는 중 오류가 발생했습니다."); return; 
}

m.jsReplace("skin_list.jsp?" + m.qs("id, idx"));

%>