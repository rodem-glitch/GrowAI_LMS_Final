<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(18, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
GroupDao group = new GroupDao();
GroupUserDao groupUser = new GroupUserDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = group.find("id = '" + id + "' AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
if(-1 == groupUser.execute("DELETE FROM " + groupUser.table + " WHERE group_id = " + id + "")) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

//삭제
if(-1 == group.execute("UPDATE " + group.table + " SET status = -1 WHERE id = " + id + "")) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

//이동
m.jsReplace("group_list.jsp");

%>