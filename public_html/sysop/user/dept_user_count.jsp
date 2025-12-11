<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserDeptDao userDept = new UserDeptDao();
UserDao user = new UserDao();

//기본키
int id = m.ri("id");
String childYn = m.rs("child_yn", "N");

if(id == 0) { return; }

userDept.getAllList(siteId);

int userCnt = user.getOneInt(
    "SELECT COUNT(*) "
    + " FROM " + user.table + " a "
    + " INNER JOIN " + userDept.table + " d ON a.dept_id = d.id AND d.site_id = " + siteId + " AND d.status = 1 "
    + " WHERE a.site_id = " + siteId + " AND a.status = 1 "
    + ("Y".equals(childYn) ? " AND a.dept_id IN (" + userDept.getSubIdx(siteId, id) + ")" : " AND a.dept_id = " + id + "")
);

out.print(m.nf(userCnt) + "명");
%>