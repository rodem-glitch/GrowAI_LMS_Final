<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
GroupDao group = new GroupDao();
UserDao user = new UserDao();
GroupUserDao groupUser = new GroupUserDao();

//기본키
int gid = m.ri("gid");
String type = m.rs("type", "I");

if(gid == 0) { return; }

//정보
DataSet ginfo = group.find("id = '" + gid + "' AND site_id = " + siteinfo.i("id") + "");
if(!ginfo.next()) { return; }
String depts = !"".equals(ginfo.s("depts")) ? m.replace(ginfo.s("depts").substring(1, ginfo.s("depts").length()-1), "|", ",") : "";
int userCnt = user.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + user.table + " a "
	+ " WHERE a.site_id = " + siteId + " AND"
	+ (!"".equals(depts) ? " a.status = 1 AND ( a.dept_id IN (" + depts + ") OR " : " ( a.status = 1 AND ")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + groupUser.table + " "
		+ " WHERE group_id = " + gid + " AND add_type = 'A' "
		+ " AND user_id = a.id "
	+ " ) ) AND NOT EXISTS ( "
		+ " SELECT 1 FROM " + groupUser.table + " "
		+ " WHERE group_id = " + gid + " AND add_type = 'D' "
		+ " AND user_id = a.id "
	+ " ) "
	+ ("A".equals(type) ? " AND a.email_yn = 'Y'" : "")
	+ ("SA".equals(type) ? " AND a.sms_yn = 'Y'" : "")
);

out.print(m.nf(userCnt) + "명");

%>