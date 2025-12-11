<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(125, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SitemapDao sitemap = new SitemapDao();
CodeDao code = new CodeDao();

//목록
DataSet list = sitemap.query(
	"SELECT a.*, b.scnt"
	+ " FROM " + sitemap.table + " a"
	+ " LEFT JOIN ("
	+ " SELECT parent_id, COUNT(*) scnt"
	+ " FROM " + sitemap.table
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
p.setBody("sitemap.sitemap_move");
p.setVar("p_title", "사이트메뉴 이동");
p.setVar("root_cnt", sitemap.findCount("status = 1 AND depth = 1") +1);
p.setLoop("list", list);

p.display();

%>