<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
SitemapDao sitemap = new SitemapDao();
//변수
boolean isMobile = "Y".equals(m.rs("is_mobile", "N"));

//목록
DataSet list = sitemap.find(
	"site_id = " + siteId + (!userB2BBlock ? " AND depth = 1 AND code != 'member'" : " AND depth = 2 AND parent_cd = '" + (!isMobile ? "b2b" : "b2bm") + "'")
	+ " AND display_type IN " + (userId > 0 ? "('A', 'I')" : "('A', 'O')")
	+ " AND display_yn = 'Y' AND status = 1 "
	, "*"
	, "sort ASC"
);

//출력
p.setLayout(null);
p.setBody("layout.top" + (userB2BBlock ? "_b2b" : ""));
p.setLoop("top_menu", list);
p.display();

%>