<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String mid = m.rs("mid");
if("".equals(mid)) {
	m.jsAlert("접근가능한 메뉴가 없습니다.\\n 관리자에게 문의하세요.");
	m.jsReplace("../main/logout.jsp", "top");
	return;
}

//객체
MenuDao menu = new MenuDao();
CodeDao code = new CodeDao();
BoardDao board = new BoardDao();

//메뉴정보
DataSet info = menu.find("id = '" + mid + "'");
if(!info.next()) {
	m.jsError("해당 정보가 없습니다.");
	return;
}

Vector<String> v = new Vector<String>();
if(!"S".equals(userKind)) v.add("a.user_id = " + userId);

//목록-메뉴
DataSet menus = menu.query(
	"SELECT b.id "
	+ ", MAX(b.parent_id) parent_id, MAX(b.menu_nm) name, MAX(b.sort) sort "
	+ ", MAX(b.link) link, MAX(b.depth) depth, MAX(b.target) target, MAX(b.icon) icon"
	+ " FROM " + new UserMenuDao().table + " a"
	+ " INNER JOIN " + menu.table + " b ON a.menu_id = b.id AND b.status = 1 AND b.menu_type = 'ADMIN' "
	+ " INNER JOIN " + SiteMenu.table + " sm ON a.menu_id = sm.menu_id AND sm.site_id = " + siteId
	+ " WHERE b.status = 1 " + (v.isEmpty() ? "" : " AND " + (m.join(" AND ", v.toArray())))
	+ ("".equals(siteinfo.s("pubtree_token")) ? " AND b.id NOT IN (117, 120)" : "")
	+ " GROUP BY b.id"
	+ " ORDER BY MAX(b.depth) ASC, MAX(b.sort) ASC"
);
menus.last();

//목록-게시판
DataSet boards = board.query(
	"SELECT a.id, a.code, a.board_nm"
	+ " FROM " + board.table + " a "
	+ " WHERE a.status = 1 AND a.site_id = " + siteId + ""
	+ " ORDER BY a.board_type ASC, a.board_nm ASC"
);
while(boards.next()) {
	menus.addRow();
	menus.put("id", boards.s("code"));
	menus.put("parent_id", "80");
	menus.put("name", boards.s("board_nm"));
	menus.put("sort", boards.i("__ord"));
	menus.put("link", "../board/index.jsp?code=" + boards.s("code"));
	menus.put("depth", 3);
	menus.put("target", "_Main");
	menus.put("icon", "");
}


//접근가능메뉴 메뉴 목록
code.setData(menus);

DataSet list = code.getTree(mid);
while(list.next()) {
	if(list.i("parent_id") == 0) {
		list.put("parent_id", "_ROOT_");
		list.put("name", "<strong>" + list.s("name") + "</strong>");
	}
}

//페이지 출력
p.setLayout("blank");
p.setBody("main.menu");
p.setVar("info", info);
p.setLoop("list", list);
p.setVar("mid", mid);
p.display();

%>