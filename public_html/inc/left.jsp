<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String pcode = m.rs("pcode");
boolean useSub = "Y".equals(m.rs("sub"));
int depth = m.ri("depth", 2);
int depthEnd = useSub ? depth + 1 : depth;

//객체
SitemapDao sitemap = new SitemapDao(siteId);

//목록
sitemap.setData(sitemap.getList());
DataSet list = new DataSet();
DataSet rs = sitemap.getList(pcode, "display_type IN " + (userId > 0 ? "('A', 'I')" : "('A', 'O')") + " AND display_yn = 'Y'");


rs.first();
while(rs.next()) {
	if(!rs.b("display_yn") || depth > rs.i("depth") || depthEnd < rs.i("depth")) continue;
	list.addRow(rs.getRow());
	list.put("is_sub", depth < rs.i("depth"));
}

//출력
p.setLayout(null);
p.setBody("layout.left");
p.setLoop("sub_menu", list);
p.setVar("class", m.rs("class", "lnb_list"));
p.display();

%>