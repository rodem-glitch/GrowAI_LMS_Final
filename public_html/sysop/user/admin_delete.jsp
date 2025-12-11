<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(17, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
UserMenuDao userMenu = new UserMenuDao();

//정보
DataSet info = user.find("id = " + id + " AND site_id = " + siteId + " AND user_kind IN ('C', 'D', 'A', 'S') AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한
if(0 == user.findCount("status = 1 AND user_kind = 'S' AND site_id = " + siteId + " AND id != '" + id + "'")) {
	m.jsError("최고 관리자는 최소 한 명이상 이여야 합니다. 삭제할 수 없습니다.");
	return;
}

//삭제
if(-1 == user.execute("UPDATE " + user.table + " SET status = -1 WHERE id = " + id + "")) {
	m.jsError("삭제하는 중에 오류가 발생하였습니다.");
	return;
}

//삭제-유저메뉴
if(-1 == user.execute("DELETE FROM " + userMenu.table + " WHERE user_id = " + id + "")) {
	m.jsError("삭제하는 중에 오류가 발생하였습니다.");
	return;
}

//이동
m.jsReplace("admin_list.jsp");

%>