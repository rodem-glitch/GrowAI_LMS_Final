<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String idx = m.rs("idx");
int mid = m.ri("mid");
if(0 == mid) { m.jsError("기본키는 지정해야 합니다."); return; }

//객체
UserMenuDao userMenu = new UserMenuDao();
UserDao user = new UserDao();

String[] users = idx.split("\\,");

DataSet list = userMenu.query(
	"SELECT a.user_id, a.menu_id, b.user_kind "
	+ " FROM " + userMenu.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id "
	+ " WHERE a.menu_id = " + mid
);
while(list.next()) {
	if(list.s("user_kind").equals("A") || list.s("user_kind").equals("C")) {
		userMenu.execute("DELETE FROM " + userMenu.table + " WHERE menu_id = " + mid + " AND user_id = " + list.i("user_id"));
	}
}

if(users != null) {
	for(int i=0; i<users.length; i++) {
		userMenu.item("menu_id", mid);
		userMenu.item("user_id", users[i]);
		userMenu.item("site_id", siteId);
		if(!userMenu.insert()) {}
	}
}

out.print("<script>parent.opener.top._Menu.location.href = parent.opener.top._Menu.location.href;</script>");
out.print("<script>parent.window.close();</script>");


%>