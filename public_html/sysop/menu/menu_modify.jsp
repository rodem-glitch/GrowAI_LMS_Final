<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(2, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//메뉴 타입, 아이디
int id = m.ri("id");

//아이디 유효성 체크
if("".equals(id)) {
	m.jsError("기본키는 반드시 지정해야 합니다.");
	return;
}

//객체
BoardDao board = new BoardDao();
MenuDao menu = new MenuDao();
CodeDao code = new CodeDao();
//menu.setDebug(out);

//정보 검사(메뉴)
DataSet info = menu.find("id = " + id + "");
if(!info.next()) {
	m.jsError("해당 정보가 없습니다.");
	return;
}

code.pName = "parent_id";
code.nName = "menu_nm";
code.rootNode = "0";
code.setData(menu.find("status = 1"));

boolean changeParent = m.isPost() && !"".equals(f.get("pmenu_id")) && !f.get("pmenu_id").equals(info.s("parent_id"));

String pid = changeParent ? f.get("pmenu_id") : info.s("parent_id");

//상위 정보
DataSet pinfo = menu.find("id = '" + pid + "'");
int maxSort = pinfo.next() ? menu.findCount("menu_type = 'ADMIN' AND parent_id = '" + pinfo.s("id") + "' AND depth = " + (pinfo.i("depth") + 1)) : menu.findCount("menu_type = 'ADMIN' AND depth = 1");

//순서
DataSet sortList = new DataSet();
for(int i=1; i<=maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i);
}

//게시판
DataSet boardList = board.find("");

//폼체크
f.addElement("mid", info.i("id"), "hname:'아이디'");
f.addElement("menu_nm", info.s("menu_nm"), "hname:'메뉴명', required:'Y'");
f.addElement("layout", info.s("layout"), "hname:'레이아웃'");
f.addElement("icon", info.s("icon"), "hname:'icon'");
f.addElement("link", info.s("link"), "hname:'링크주소'");
f.addElement("target", info.s("target"), "hname:'타겟'");
f.addElement("display_yn", info.s("display_yn"), "hname:'타사이트 사용여부', required:'Y'");
f.addElement("sort", info.i("sort"), "hname:'순서', required:'Y', option:'number'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

//수정
if(m.isPost() && f.validate()) {

	menu.item("menu_nm", f.get("menu_nm"));
	menu.item("layout", f.get("layout"));
	menu.item("icon", f.get("icon"));
	menu.item("target", f.get("target"));
	menu.item("link", f.get("link"));
//	menu.item("sort", f.getInt("sort"));
	menu.item("status", f.getInt("status"));
	menu.item("display_yn", f.get("display_yn", "N"));
	menu.item("parent_id", pid);

	if(!menu.update("id = " + id)) {
		m.jsError("수정하는 중 오류가 발생했습니다.");
		return;
	}

	if(changeParent) {

		int cdepth = pinfo.i("depth") + 1 - info.i("depth");
		if(cdepth != 0) {
			menu.execute("update " + menu.table + " SET depth = depth + (" + cdepth + ") WHERE id IN('" + m.join("','", code.getChildNodes(""+id)) + "')");
		}
		menu.sortMenu(id, f.getInt("sort"), maxSort + 1);
		menu.autoSort(info.i("depth"), info.i("parent_id"), "ADMIN");
	} else {
		//순서정렬
		menu.sortMenu(info.i("id"), f.getInt("sort"), info.i("sort"));

	}

	//페이지 파일 생성
	//menu.createFile(f.get("link"), ""+id);

	out.print("<script>parent.left.location.href='menu_tree.jsp?&sid=" + id + "';</script>");
	m.jsReplace("menu_modify.jsp?" + m.qs());
	return;

}

Vector pName = code.getParentNames(""+id);
String names = "";
for(int i=(pName.size() -1); i > 0; i--) {
	names += pName.get(i).toString() + ( i == 1 ? "" : " > ");
}
info.put("parent_name", "".equals(names) ? "-" : names);

//페이지 출력
p.setLayout("blank");
p.setBody("menu.menu_insert");
p.setVar("p_title", "관리자 메뉴");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("pinfo", pinfo);
p.setVar(info);
p.setVar("modify", true);
p.setLoop("sort_list", sortList);
p.setLoop("layout_list", menu.getLayouts(docRoot + "/sysop/html/layout"));

p.display();

%>