<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(2, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
MenuDao menu = new MenuDao();
CodeDao code = new CodeDao();

//목록
DataSet list = menu.query(
	"SELECT a.*, b.scnt"
	+ " FROM " + menu.table + " a"
	+ " LEFT JOIN ("
	+ " SELECT parent_id, COUNT(*) scnt"
	+ " FROM " + menu.table
	+ " WHERE status = 1"
	+ " GROUP BY parent_id"
	+ ") b ON a.id = b.parent_id"
	+ " WHERE a.status = 1 AND a.menu_type = 'ADMIN'"
	+ " ORDER BY a.parent_id ASC, a.sort ASC"
);

code.setData(list);
Vector<String> v = "".equals(m.rs("tid")) ? new Vector() : code.getChildNodes(code.getChildNodes(m.rs("tid")));

//포맷팅
while(list.next()) {
	list.put("scnt", list.i("scnt") + 1);
	list.put("is_child", v.contains(list.s("id")));
}

//출력
p.setLayout("pop");
p.setBody("menu.menu_move");
p.setVar("p_title", "메뉴이동 관리");
p.setVar("root_cnt", menu.findCount("status = 1 AND depth = 1") +1);
p.setLoop("list", list);

p.display();

%>