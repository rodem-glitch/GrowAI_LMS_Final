<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근가능한 상위 메뉴
/*
DataSet list = Menu.query(
	"SELECT b.id, MAX(b.type) type, MAX(b.parent_id) parent_id, MAX(b.name)name, MAX(b.sort)sort, MAX(b.link)link,"
	+ "MAX(b.depth)depth, MAX(b.target)target, MAX(b.icon)icon "
	+ "FROM " + new AuthMenuDao().table + " a "
	+ "INNER JOIN " + Menu.table + " b ON a.menu_id = b.id AND b.status = 1 AND b.type = 'ADMIN'"
	+ " WHERE a.type = 'ADMIN' AND b.parent_id = '-' AND a.auth_id IN (" + authId + ")"
	+ " GROUP BY b.id ORDER BY MAX(b.sort) ASC"
);

if(list.size() == 0) {
	m.jsAlert("접근 허용된 관리메뉴가 없습니다.\\n관리자에게 문의하세요.");
	m.jsReplace("../main/logout.jsp", "top");
	return;
}
*/

MenuLocaleDao menuLocale = new MenuLocaleDao();

DataSet list = Menu.query(
	"SELECT b.id, MAX(b.menu_type) type, MAX(b.parent_id) parent_id, MAX(COALESCE(ml.menu_locale_nm, b.menu_nm)) name, MAX(b.sort) sort, MAX(b.link) link, MAX(b.depth) depth, MAX(b.target) target, MAX(b.icon) icon "
	+ " FROM " + new UserMenuDao().table + " a "
	+ " INNER JOIN " + Menu.table + " b ON a.menu_id = b.id AND b.status = 1 AND b.menu_type = 'ADMIN' AND b.id > 0 "
	+ " INNER JOIN " + SiteMenu.table + " sm ON a.menu_id = sm.menu_id AND sm.site_id = " + siteId
	+ " LEFT JOIN " + menuLocale.table + " ml ON b.id = ml.menu_id AND ml.locale_cd = 'default' "
	+ " WHERE b.parent_id = 0 AND b.display_yn = 'Y' "
	+ (!"S".equals(userKind) ? " AND a.user_id = " + userId : "")
	+ " GROUP BY b.id "
	+ " ORDER BY MAX(b.sort) ASC"
);
if(list.size() == 0) {
	m.jsAlert("접근 허용된 관리메뉴가 없습니다.\\n관리자에게 문의하세요.");
	m.jsReplace("../main/logout.jsp", "top");
	return;
}


//출력
p.setLayout(!"clear".equals(m.rs("mode")) ? "blank" : "clear");
p.setBody("main.top");

p.setVar("mid", m.rs("mid"));
p.setVar("lnb", m.rs("lnb"));
p.setVar("user_name", userName);
p.setVar("remote_ip", userIp);
p.setLoop("list", list);
p.display();

%>