<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(18, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
GroupDao group = new GroupDao();
GroupUserDao groupUser = new GroupUserDao();

//기본키
int gid = m.ri("gid");
if(gid == 0 || "".equals(m.rs("idx"))) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet ginfo = group.find("id = '" + gid + "' AND site_id = " + siteinfo.i("id") + "");
if(!ginfo.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼입력
String[] idx = m.rs("idx").split(",");

//삭제
if(-1 == groupUser.execute(
	"DELETE FROM " + groupUser.table + " "
	+ " WHERE group_id = " + gid + " "
	+ " AND user_id IN (" + m.join(",", idx) + ") "
)) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

//이동
m.jsReplace("../user/group_modify.jsp?id=" + gid);

%>