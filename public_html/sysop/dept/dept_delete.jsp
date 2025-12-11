<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(43, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDeptDao userDept = new UserDeptDao();
UserDao user = new UserDao();

//정보
DataSet info = userDept.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다"); return; }

//제한
if(0 < userDept.findCount("parent_id = " + id + " AND status != -1")) {
	m.jsError("하위 분류가 있습니다. 삭제할 수 없습니다.");
	return;
}

//제한
if(0 < user.findCount("dept_id = " + id + " AND status != -1")) {
	m.jsError("회원정보에서 사용 중인 분류입니다. 삭제할 수 없습니다.");
	return;
}


//삭제
if(-1 == userDept.execute("UPDATE " + userDept.table + " SET status = -1 WHERE id = " + id + "")) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

//순서
userDept.autoSort(info.i("depth"), info.i("parent_id"), siteId);

//이동
m.js("parent.left.location.href = parent.left.location.href;");
m.jsReplace("dept_insert.jsp?" + m.qs("id, sid"));

%>