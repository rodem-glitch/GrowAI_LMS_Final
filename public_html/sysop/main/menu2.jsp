<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String mid = m.rs("mid");
if("".equals(mid)) {
	//m.jsAlert("접근가능한 메뉴가 없습니다.\\n 관리자에게 문의하세요.");
	//m.jsReplace("../main/logout.jsp", "top");
	return;
}

//객체
MenuDao menu = new MenuDao();
CodeDao code = new CodeDao();
BoardDao board = new BoardDao();
FormmailDao formmail = new FormmailDao();
UserMenuDao userMenu = new UserMenuDao();
ShortcutDao shortcut = new ShortcutDao();
MenuLocaleDao menuLocale = new MenuLocaleDao();

//메뉴정보
DataSet info = menu.find("id = '" + mid + "'");
if(!info.next()) {
	m.jsError("해당 정보가 없습니다.");
	return;
}

//목록-메뉴
//menu.setDebug(out);
DataSet menus = menu.query(
/*
	"SELECT m.id "
	+ ", MAX(m.parent_id) parent_id, MAX(COALESCE(ml.menu_locale_nm, m.menu_nm)) name, MAX(m.sort) sort "
	+ ", MAX(m.link) link, MAX(m.depth) depth, MAX(m.target) target, MAX(m.open_yn) open_yn, MAX(m.icon) icon "
	+ " FROM " + menu.table + " m "
	+ (!"S".equals(userKind) ? " INNER JOIN " + userMenu.table + " um ON um.menu_id = m.id AND m.status = 1 AND m.menu_type = 'ADMIN' AND um.user_id = " + userId : "")
	+ " INNER JOIN " + SiteMenu.table + " sm ON m.id = sm.menu_id AND sm.site_id = " + siteId
	+ " LEFT JOIN " + menuLocale.table + " ml ON m.id = ml.menu_id AND ml.locale_cd = 'default' "
	+ " WHERE m.status = 1 AND m.display_yn = 'Y' "
	+ " GROUP BY m.id "
	+ " ORDER BY MAX(m.depth) ASC, MAX(m.sort) ASC "
*/
	"SELECT m.id "
	+ ", m.parent_id, m.menu_nm name, m.sort sort "
	+ ", m.link, m.depth, m.target, m.open_yn, m.icon "
	+ " FROM " + SiteMenu.table + " sm"
	+ " INNER JOIN " + menu.table + " m ON m.id = sm.menu_id"
	+ (!"S".equals(userKind) ? " INNER JOIN " + userMenu.table + " um ON um.menu_id = sm.menu_id AND um.user_id = " + userId : "")
	+ " WHERE sm.site_id = " + siteId + " AND m.status = 1 AND m.display_yn = 'Y' AND m.menu_type = 'ADMIN' "
	+ " ORDER BY m.depth ASC, m.sort ASC"
);

menus.last();

if("4".equals(mid)) {
	//목록-게시판
	DataSet boards = board.query(
		"SELECT a.id, a.code, a.board_nm, a.breadscrumb"
		+ " FROM " + board.table + " a "
		+ " WHERE a.status = 1 AND a.site_id = " + siteId + ""
		+ (!("A".equals(userKind) || "S".equals(userKind)) ? " AND a.admin_idx LIKE '%|" + userId + "|%'" : "")
		+ " ORDER BY a.sort ASC, a.board_type ASC, a.board_nm ASC"
	);
	while(boards.next()) {
		menus.addRow();
		menus.put("id", boards.s("code"));
		menus.put("parent_id", "80");
		menus.put("name"
			, (!"".equals(boards.s("breadscrumb")) ? "<span class=\"nav-desc\">[" + m.addSlashes(boards.s("breadscrumb")) + "]</span> " : "")
			+ m.addSlashes(boards.s("board_nm"))
		);
		menus.put("sort", boards.i("__ord"));
		menus.put("link", "../board/index.jsp?code=" + boards.s("code"));
		menus.put("depth", 3);
		menus.put("target", "_Main");
		menus.put("icon", "fa-list");
	}

	//목록-폼메일카테고리
	DataSet formmails = formmail.query("SELECT DISTINCT category_nm FROM " + formmail.table + " WHERE category_nm IS NOT NULL AND category_nm != '' AND site_id = " + siteId + " AND status != -1 ORDER BY category_nm ASC");

	if(0 < formmails.size()) {
		menus.addRow();
		menus.put("id", "formmail_all");
		menus.put("parent_id", "80");
		menus.put("name", "전체이메일문의");
		menus.put("sort", 1);
		menus.put("link", "../formmail/formmail_list.jsp");
		menus.put("depth", 3);
		menus.put("target", "_Main");
		menus.put("icon", "fa-envelope-open-text");
	}

	while(formmails.next()) {
		menus.addRow();
		menus.put("id", "formmail_" + formmails.s("category_nm"));
		menus.put("parent_id", "80");
		menus.put("name", formmails.s("category_nm"));
		menus.put("sort", formmails.i("__ord") + 1);
		menus.put("link", "../formmail/formmail_list.jsp?s_category_nm=" + m.urlencode(formmails.s("category_nm")));
		menus.put("depth", 3);
		menus.put("target", "_Main");
		menus.put("icon", "fa-envelope-open-text");
	}
}

//정렬
code.setData(menus);

DataSet list = code.getTree(mid);
while(list.next()) {
	if(list.i("parent_id") == 0) {
		list.put("parent_id", "_ROOT_");
		list.put("name", "<strong>" + list.s("name") + "</strong>");
	}
	if("".equals(list.s("icon"))) list.put("icon", (2 == list.i("depth") ? "fa-folder" : "fa-angle-right"));
}

//출력-JSON
if("json".equals(m.rs("mode"))) {
	response.setContentType("application/json;charset=utf-8");
	out.print(list.serialize());
	return;
}

//출력
p.setLayout("blank");
p.setBody("main.menu2");

p.setVar("info", info);
p.setLoop("list", list);

p.setVar("mid", mid);
p.setVar("lnb", m.rs("lnb"));

p.setLoop("site_shortcut_list", shortcut.find("user_id = -99 AND site_id = " + siteId + " AND status = 1", "*", "sort ASC"));
p.setLoop("user_shortcut_list", shortcut.find("user_id = " + userId + " AND site_id = " + siteId + " AND status = 1", "*", "sort ASC"));
p.display();

%>