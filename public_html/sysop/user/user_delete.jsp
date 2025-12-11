<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(19, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();

//정보
DataSet info = user.find("id = " + id + " AND site_id = " + siteId + " AND user_kind = 'U' AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한

//삭제
if(-1 == user.execute("UPDATE " + user.table + " SET status = -1 WHERE id = " + id + "")) {
	m.jsError("삭제하는 중에 오류가 발생하였습니다.");
	return;
}

//이동
m.jsReplace("user_list.jsp");

%>