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
LmCategoryDao category = new LmCategoryDao("webtv");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();

String where = " display_yn = 'Y' "
	+ " AND (target_yn = 'N'" //시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + categoryTarget.table + " WHERE category_id = id AND group_id IN (" + userGroups + "))"
		: "")
	+ " ) "
	+ (1 > userId ? " AND login_yn = 'N' " : "");
category.setData(category.getList(siteId));
DataSet rs = category.getList(siteId, lnb, where);

while(rs.next()) {
	if(!rs.b("display_yn") || depth > rs.i("depth") || depthEnd < rs.i("depth")) continue;

	out.println(
		"<li" + (idYn ? " id=\"" + mode + "_WEBTV_" + rs.s("id") + "\"" : "") + " class=\"" + (depth < rs.i("depth") ? "lnb_sub" : "") + " " + cssClass + "\">"
			+ "<a href=\"/" + (!isMobile ? "webtv" : "mobile") + "/webtv_list.jsp?cid=" + rs.s("id") + ((0 < lnb && lnbInherit) ? "&lnb=" + lnb : "") + "&ch=" + ch + "\" title=\""+ rs.s("category_nm") +" 페이지로 이동\">"+ rs.s("category_nm") +"</a>"
		+ "</li>"
	);
}

%>