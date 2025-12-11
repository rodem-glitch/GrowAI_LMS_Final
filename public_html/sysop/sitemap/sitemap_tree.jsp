<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(125, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SitemapDao sitemap = new SitemapDao(siteId);

//목록
DataSet list = sitemap.find("site_id = " + siteId + (!"Y".equals(SiteConfig.s("join_b2b_yn")) ? " AND code NOT LIKE 'b2b%'" : "") + " AND status != -1", "*", "parent_cd ASC, sort ASC");

//출력
p.setLayout("blank");
p.setBody("sitemap.sitemap_tree");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());

p.setLoop("list", list);
p.display();

%>