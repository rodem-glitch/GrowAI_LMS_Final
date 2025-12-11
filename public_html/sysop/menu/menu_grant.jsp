<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(2, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int mid = m.ri("mid");
if(mid == 0) { m.jsError("기본키는 지정해야 합니다."); return; }

//객체
UserMenuDao userMenu = new UserMenuDao();
UserDao user = new UserDao();

//정보
DataSet list = user.query(
	"SELECT a.id, a.login_id, a.user_nm, a.user_kind, b.menu_id "
	+ " FROM " + user.table + " a "
	+ " LEFT JOIN " + userMenu.table + " b ON a.id = b.user_id AND b.menu_id = " + mid + ""
	+ " WHERE a.status = 1 AND a.user_kind IN ('C', 'D', 'A', 'S') "
	+ " AND a.site_id = " + siteId + " "
	+ " ORDER BY a.user_nm ASC "
);
while(list.next()) {
	list.put("checked", list.i("menu_id") > 0 ? "checked" : "");
	list.put("user_kind_conv", m.getItem(list.s("user_kind"), user.kinds));
}

//출력
p.setLayout("pop");
p.setBody("menu.menu_grant");
p.setVar("p_title", "메뉴권한관리");
p.setVar("list_query", m.qs("id"));
p.setLoop("list", list);

p.display();
%>