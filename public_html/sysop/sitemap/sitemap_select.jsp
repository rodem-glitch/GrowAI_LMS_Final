<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String tcode = m.rs("tcode");
String mode = !"".equals(m.rs("mode")) ? m.rs("mode") : "move";

//객체
SitemapDao sitemap = new SitemapDao(siteId);

//목록
DataSet list = sitemap.query(
	" SELECT a.*, b.cnt "
	+ " FROM " + sitemap.table + " a "
	+ " LEFT JOIN ( "
		+ " SELECT parent_cd, COUNT(*) cnt FROM " + sitemap.table + " WHERE status = 1 AND site_id = " + siteId + " GROUP BY parent_cd "
	+ " ) b ON a.code = b.parent_cd "
	+ " WHERE a.status = 1 AND a.site_id = " + siteId + " "
	+ " ORDER BY a.parent_cd ASC, a.sort ASC "
);
sitemap.setData(list);
String[] arr = !"".equals(tcode) ? sitemap.getChildNodes(tcode) : null;
list.first();
while(list.next()) {
	list.put("cnt", list.i("cnt") + 1);
	list.put("is_child", m.inArray(list.s("code"), arr));
}

//출력
p.setLayout("pop");
p.setBody("sitemap.sitemap_select");
p.setVar("p_title", "사이트메뉴 선택");
p.setLoop("list", list);

p.setVar(mode + "_block", true);
p.setVar("root_cnt", sitemap.findCount("site_id = " + siteId + " AND status = 1 AND depth = 1") + 1);
p.display();

%>