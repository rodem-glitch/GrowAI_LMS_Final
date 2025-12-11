<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
boolean useSub = "Y".equals(m.rs("sub"));
boolean lnbInherit = "Y".equals(m.rs("lnb_inherit", "Y"));
int lnb = m.ri("lnb");
int depth = m.ri("depth", 1);
int depthEnd = useSub ? depth + 1 : depth;
String mode = !"".equals(m.rs("mode")) ? m.rs("mode") : "LNB";
String cssClass = m.rs("css_class");
boolean isMobile = "Y".equals(m.rs("is_mobile"));
boolean idYn = "Y".equals(m.rs("id_yn", "Y"));

//객체
LmCategoryDao category = new LmCategoryDao("book");










category.setData(category.getList(siteId));
DataSet rs = category.getList(siteId, lnb, "display_yn = 'Y'");

while(rs.next()) {
	if(!rs.b("display_yn") || depth > rs.i("depth") || depthEnd < rs.i("depth")) continue;

	out.println(
		"<li" + (idYn ? " id=\"" + mode + "_BOOK_"+ rs.s("id") +"\"" : "") + " class=\"" + (depth < rs.i("depth") ? "lnb_sub" : "") + " " + cssClass + " dep1\">"
			+ "<a href=\"/" + (!isMobile ? "book" : "mobile") + "/book_list.jsp?cid="+ rs.s("id") + ((0 < lnb && lnbInherit) ? "&lnb=" + lnb : "") + "&ch=" + ch + "\" title=\""+ rs.s("category_nm") +" 페이지로 이동\">"+ rs.s("category_nm") +"</a>"
		+ "</li>"
	);
}

%>