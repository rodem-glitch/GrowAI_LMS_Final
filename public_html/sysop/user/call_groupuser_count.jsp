<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.30

//객체
GroupDao group = new GroupDao();
UserDao user = new UserDao();
GroupUserDao groupUser = new GroupUserDao();

//기본키
int id = m.ri("gid");
if(id == 0) return;

//정보
DataSet info = group.find("id = '" + id + "' AND site_id = " + siteId + "");
if(!info.next()) return;

//갱신
String[] idx = f.get("dp_idx").split(",");
if(idx != null) group.item("depts", "|" + m.join("|", idx) + "|");
if(!group.update("id = '" + id + "'")) return;

//유저수
int userCnt = user.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + user.table + " a "
	+ " WHERE a.site_id = " + siteId + " AND"
	+ (!"".equals(f.get("dp_idx")) ? " a.status = 1 AND ( a.dept_id IN (" + f.get("dp_idx") + ") OR " : " ( a.status = 1 AND ")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + groupUser.table + " "
		+ " WHERE group_id = " + id + " AND add_type = 'A' "
		+ " AND user_id = a.id "
	+ " ) ) AND NOT EXISTS ( "
		+ " SELECT 1 FROM " + groupUser.table + " "
		+ " WHERE group_id = " + id + " AND add_type = 'D' "
		+ " AND user_id = a.id "
	+ " ) "
);

out.print(m.nf(userCnt));

%>