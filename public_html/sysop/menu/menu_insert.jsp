<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(2, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//상위메뉴, 타입
int pmenu = m.ri("pmenu");

//객체
BoardDao board = new BoardDao();
MenuDao menu = new MenuDao();
CodeDao code = new CodeDao();
UserMenuDao userMenu = new UserMenuDao();
UserDao user = new UserDao();
SiteMenuDao siteMenu = new SiteMenuDao();

//순서
int maxSort = 0;
DataSet pinfo = new DataSet();
if(0 != pmenu) {
	pinfo = menu.find("id = " + pmenu + "");
	if(!pinfo.next()) {
		m.jsError("상위메뉴 정보가 없습니다.");
		return;
	}
	maxSort = menu.findCount("menu_type = 'ADMIN' AND parent_id = " + pinfo.s("id") + " AND depth = " + (pinfo.i("depth") + 1));
} else {
	pinfo.addRow();
	pinfo.put("parent_id", "0");
	pinfo.put("depth", 0);
	maxSort = menu.findCount("menu_type = 'ADMIN' AND depth = 1");
}

//순서
DataSet sortList = new DataSet();
for(int i=0; i<=maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i+1);
}

//게시판
DataSet boardList = board.find("");

//폼체크
f.addElement("mid", null, "hname:'아이디', required:'Y', option:'number'");
f.addElement("parent_id", null, "hname:'상위메뉴값'");
f.addElement("menu_nm", null, "hname:'메뉴명', required:'Y'");
f.addElement("icon", null, "hname:'icon'");
f.addElement("link", null, "hname:'링크주소'");
f.addElement("target", "_Main", "hname:'타겟', required:'Y'");
f.addElement("layout", "sysop", "hname:'레이아웃', required:'Y'");
f.addElement("sort", (maxSort + 1), "hname:'순서', required:'Y', option:'number'");
f.addElement("display_yn", "N", "hname:'타사이트 사용여부', required:'Y'");
f.addElement("status", null, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int check = menu.findCount("id = " + f.getInt("mid") + "");
	if(0 < check) {
		m.jsAlert("입력하신 아이디는 사용 중입니다.");
		m.jsReplace("menu_insert.jsp?pmenu=" + pmenu + "");
		return;
	}

	menu.item("id", f.getInt("mid"));
	menu.item("parent_id", "".equals(f.get("pmenu_id")) ? "0" : f.get("pmenu_id"));
	menu.item("menu_type", "ADMIN");
	menu.item("menu_nm", f.get("menu_nm"));
	menu.item("icon", f.get("icon"));
	menu.item("link", f.get("link"));
	menu.item("target", f.get("target"));
	menu.item("depth", pinfo.i("depth") + 1);
	menu.item("layout", f.get("layout"));
//	menu.item("sort", f.getInt("sort"));
	menu.item("display_yn", f.get("display_yn", "N"));
	menu.item("reg_date", m.time("yyyyMMddHHmmss"));
	menu.item("status", f.getInt("status"));

	if(!menu.insert()) {
		m.jsError("등록하는 중 오류가 발생했습니다.");
		return;
	}

	if(0 != f.getInt("pmenu_id")) {
		m.setCookie("mmdIns", f.get("pmenu_id"));
	}
	int newId = menu.getInsertId();

	menu.sortMenu(newId, f.getInt("sort"), maxSort + 1);

	//페이지 파일 생성
//	menu.createFile(f.get("link"), ""+newId);

	//슈퍼관리자한테는 모두 메뉴추가
	DataSet list = user.find("user_kind = 'S' AND status = 1");
	while(list.next()) {
		userMenu.item("menu_id", newId);
		userMenu.item("user_id", list.i("id"));
		userMenu.item("site_id", list.i("site_id"));

		if(!userMenu.insert()) {}
	}

	//사이트메뉴 추가
	siteMenu.item("site_id", siteId);
	siteMenu.item("menu_id", f.getInt("mid"));
	if(!siteMenu.insert()) {
		m.jsAlert("사이트메뉴 등록하는 중 오류가 발생했습니다.");
		return;
	}

	out.print("<script>parent.left.location.href='menu_tree.jsp?sid=" + pmenu + "';</script>");
	m.jsReplace("menu_insert.jsp?pmenu=" + pmenu + "");
	return;
}

//상위코드명
String names = "";
if(0 != pmenu) {
	code.pName = "parent_id";
	code.nName = "menu_nm";
	code.rootNode = "0";
	code.setData(menu.find("status = 1"));
	Vector pName = code.getParentNames(""+pmenu);
	for(int i=(pName.size() - 1); i>=0; --i) {
		names += pName.get(i).toString() + (i == 0 ? "" : " > ");
	}
}

//페이지 출력
p.setLayout("blank");
p.setBody("menu.menu_insert");
p.setVar("p_title", "관리자 메뉴");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar("pinfo", pinfo);
p.setLoop("sort_list", sortList);
p.setLoop("layout_list", menu.getLayouts(docRoot + "/sysop/html/layout"));
p.setVar("parent_name", "".equals(names) ? "-" : names);

p.display();

%>