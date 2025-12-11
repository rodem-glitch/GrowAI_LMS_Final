<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(17, userId, userKind)) { m.jsAlert("접근 권한이 없습니다."); m.js("parent.CloseLayer();"); return; }

//기본키
int uid = m.ri("uid");
if(uid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); m.js("parent.CloseLayer();"); return; }

//객체
MenuDao menu = new MenuDao();
UserMenuDao userMenu = new UserMenuDao();
UserDao user = new UserDao();
ActionLogDao actionLog = new ActionLogDao();

//변수
DataSet binfo = new DataSet();
DataSet ainfo = new DataSet();
//정보
DataSet uinfo = user.find("id = " + uid + " AND user_kind IN ('C', 'D', 'A', 'S') AND site_id = " + siteId + "");
if(!uinfo.next()) { m.jsAlert("해당 정보가 없습니다."); m.js("parent.CloseLayer();"); return; }
if("S".equals(uinfo.s("user_kind"))) { m.jsAlert("최고관리자의 메뉴권한은 수정할 수 없습니다."); m.js("parent.CloseLayer();"); return; }

//목록
DataSet list = menu.query(
	"SELECT a.*, u.menu_id mid "
	+ " FROM " + menu.table + " a "
	+ " INNER JOIN " + SiteMenu.table + " sm ON a.id = sm.menu_id AND sm.site_id = " + siteId
	+ " LEFT JOIN " + userMenu.table + " u ON u.menu_id = a.id AND u.user_id = " + uid + " "
	+ " WHERE a.menu_type = 'ADMIN' AND a.display_yn ='Y' AND a.status = 1 "
	+ " AND a.auth_access LIKE '%|" + uinfo.s("user_kind") + "|%'" 
	+ " ORDER BY a.depth ASC, a.sort ASC "
);
while(list.next()) {
	list.put("checked", !"".equals(list.s("mid")) ? "checked" : "");

	if("checked".equals(list.s("checked"))){
		binfo.addRow();
		binfo.put("id", list.i("id"));
		binfo.put("menu_nm", list.s("menu_nm"));
		binfo.put("depth", list.i("depth"));
		binfo.put("parent_id", list.i("parent_id"));
//		binfo.put("checked", list.s("checked"));
	}

	list.put("parent_id", list.i("parent_id") == 0 ? "-" : list.s("parent_id"));
	list.put("status", list.b("status"));
}


//저장
if(m.isPost() && f.validate()) {

	//삭제-이전데이터
	if(-1 == userMenu.execute("DELETE FROM " + userMenu.table + " WHERE user_id = '" + uid + "'")) {
		m.jsAlert("저장하는 중에 오류가 발생했습니다.");
		m.js("parent.CloseLayer();"); 
		return;
	}

	int failed = 0;
	userMenu.item("user_id", uid);
	userMenu.item("site_id", siteId);

	//최고관리자
	if("S".equals(uinfo.s("user_kind"))) {
		list.first();
		while(list.next()) {
			userMenu.item("menu_id", list.s("id"));
			if(!userMenu.insert()) { failed++; }
		}
	//운영자
	} else {
		String[] idx = f.getArr("idx");
		if(idx != null) {
			for(int i = 0; i < idx.length; i++) {
				userMenu.item("menu_id", idx[i]);
				if(!userMenu.insert()) {
					failed++;
				}
			}
		}
	}

	//액션로그
	DataSet alist = menu.query(
		"SELECT a.id, a.menu_nm, a.depth, a.parent_id, u.menu_id mid "
		+ " FROM " + menu.table + " a "
		+ " INNER JOIN " + SiteMenu.table + " sm ON a.id = sm.menu_id AND sm.site_id = " + siteId
		+ " LEFT JOIN " + userMenu.table + " u ON u.menu_id = a.id AND u.user_id = " + uid + " "
		+ " WHERE a.menu_type = 'ADMIN' AND a.display_yn ='Y' AND a.status = 1 "
		+ " AND a.auth_access LIKE '%|" + uinfo.s("user_kind") + "|%'"
		+ " ORDER BY a.depth ASC, a.sort ASC "
	);
	while (alist.next()){
		alist.put("checked", !"".equals(alist.s("mid")) ? "checked" : "");

		if("checked".equals(alist.s("checked"))){
			ainfo.addRow();
			ainfo.put("id", alist.i("id"));
			ainfo.put("menu_nm", alist.s("menu_nm"));
			ainfo.put("depth", alist.i("depth"));
			ainfo.put("parent_id", alist.i("parent_id"));
//			ainfo.put("checked", alist.s("checked"));
		}
	}

	actionLog.item("site_id", siteId);
	actionLog.item("user_id", userId);
	actionLog.item("module", "user_grant");
	actionLog.item("module_id", uid);
	actionLog.item("action_type", "U");
	actionLog.item("action_desc", "관리자권한변경");
	actionLog.item("before_info", binfo.serialize());
	actionLog.item("after_info", ainfo.serialize());
	actionLog.item("reg_date", m.time("yyyyMMddHHmmss"));
	actionLog.item("status", 1);
	if(!actionLog.insert()) {}


	//오류
	if(failed > 0) {
		m.jsAlert(failed + "건이 저장되지 않았습니다. 다시 저장하세요.");
		m.js("parent.CloseLayer();"); 
		return;
	}

	//out.print("<script>parent.window.close();</script>");
	m.js("parent.CloseLayer();");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("user.menu_user_grant");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);

p.display();
%>