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
String template = m.rs("template", "");
boolean templateBlock = !"".equals(template);

//객체
LmCategoryDao category = new LmCategoryDao("course");
category.setData(category.getList(siteId));

//정보
DataSet rs = category.getList(siteId, lnb, "display_yn = 'Y'");
DataSet list = new DataSet();

//포맷팅
while(rs.next()) {
	if(!rs.b("display_yn") || depth > rs.i("depth") || depthEnd < rs.i("depth")) continue;
	if(templateBlock) {
		list.addRow(rs.getRow());
	} else {
		out.println(
			"<li" + (idYn ? " id=\"" + mode + "_COURSE_"+ rs.s("id") + "\"" : "") + " class=\"" + (depth < rs.i("depth") ? "lnb_sub" : "") + " " + cssClass + "\">"
				+ "<a href=\"/" + (!isMobile ? "course" : "mobile") + "/course_list.jsp?cid=" + rs.s("id") + ((0 < lnb && lnbInherit) ? "&lnb=" + lnb : "") + "&ch=" + ch + "\" title=\""+ rs.s("category_nm") +" 페이지로 이동\">"+ rs.s("category_nm") +"</a>"
			+ "</li>"
		);
	}
}

//출력
if(templateBlock && new File(tplRoot + "/" + m.replace(template, ".", "/") +  ".html").exists()) {
	p.setLayout(null);
	p.setBody(template);
	p.setLoop("list", list);
	p.display();
}

%>