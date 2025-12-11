<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String pcode = m.rs("pcode");
boolean useSub = "Y".equals(m.rs("sub"));
int depth = m.ri("depth", 2);
int depthEnd = useSub ? depth + 1 : depth;

//객체
LmCategoryDao category = new LmCategoryDao();
SitemapDao sitemap = new SitemapDao();
HashMap<String, DataSet> subset = new HashMap<String, DataSet>();

//목록
DataSet _rs = sitemap.find(
	"site_id = " + siteId + " AND parent_cd = '" + pcode + "'"
	+ " AND display_type IN " + (userId > 0 ? "('A', 'I')" : "('A', 'O')")
	+ " AND display_yn = 'Y' AND status = 1 "
	, "code, parent_cd, menu_nm, link, target"
	, "depth,sort ASC"
);

DataSet rs = new DataSet();
while(_rs.next()) {
	String cd = _rs.s("code");
	if("allcourses".equals(cd)) {
		_rs.put("menu_nm", "전체과정");
		rs.addRow(_rs.getRow());
		DataSet crs = category.find("module = 'course' AND depth = 1 AND display_yn = 'Y' AND status = 1 AND site_id = " + siteId, "id, category_nm", "sort");
		while(crs.next()) {
			rs.addRow();
			rs.put("parent_cd", _rs.s("parent_cd"));
			rs.put("code", "course_category_" + crs.s("id"));
			rs.put("menu_nm", crs.s("category_nm"));
			rs.put("link", "/course/course_list.jsp?cid=" + crs.s("id"));
			rs.put("target", "_self");
		}
	} else if("allbooks".equals(cd)) {
		_rs.put("menu_nm", "전체도서");
		rs.addRow(_rs.getRow());
		DataSet crs = category.find("module = 'book' AND depth = 1 AND display_yn = 'Y' AND status = 1 AND site_id = " + siteId, "id, category_nm", "sort");
		while(crs.next()) {
			rs.addRow();
			rs.put("parent_cd", _rs.s("parent_cd"));
			rs.put("code", "book_category_" + crs.s("id"));
			rs.put("menu_nm", crs.s("category_nm"));
			rs.put("link", "/book/book_list.jsp?cid=" + crs.s("id"));
			rs.put("target", "_self");
		}
	} else if("allwebtv".equals(cd)) {
		_rs.put("menu_nm", "전체방송");
		rs.addRow(_rs.getRow());
		DataSet crs = category.find("module = 'webtv' AND depth = 1 AND display_yn = 'Y' AND status = 1 AND site_id = " + siteId, "id, category_nm", "sort");
		while(crs.next()) {
			rs.addRow();
			rs.put("parent_cd", _rs.s("parent_cd"));
			rs.put("code", "webtv_category_" + crs.s("id"));
			rs.put("menu_nm", crs.s("category_nm"));
			rs.put("link", "/webtv/webtv_list.jsp?cid=" + crs.s("id"));
			rs.put("target", "_self");
		}
	} else {
		rs.addRow(_rs.getRow());
	}
}
rs.first();

DataSet list = new DataSet();
while(rs.next()) {
	String pcd = rs.s("parent_cd");
	if("".equals(pcd)) {
		pcd = "_root_";
		list.addRow(rs.getRow());
	}
	if(!subset.containsKey(pcd)) subset.put(pcd, new DataSet());
	subset.get(pcd).addRow(rs.getRow());
}

//m.p(_rs);

StringBuilder sb = new StringBuilder();
createList(subset, sb, pcode, 1);
out.print(sb.toString());

%><%!

public void createList(HashMap<String, DataSet> subset, StringBuilder sb, String pcode, int no) {
	DataSet rs = subset.get(pcode);
	if(rs == null) return;
	rs.first();
	sb.append("<ul id='lnb' class='lnb_list");
	sb.append("' data-code='");
	sb.append(pcode + "'>");
	//sb.append("<ul ");
//	if(no == 1) sb.append("id='lnb' class='lnb_list' ");
//	else sb.append("class='lnb_sub' ");
//	sb.append("class='depth");
//	sb.append(Integer.toString(no));
//	sb.append("'>");
	while(rs.next()) {
		sb.append("<li id='lnb_");
		sb.append(rs.s("code"));
		sb.append("'>");
		sb.append("<a href='");
		sb.append(rs.s("link"));
		sb.append("' target='");
		sb.append(rs.s("target"));
		sb.append("'>");
		sb.append(rs.s("menu_nm"));
		sb.append("</a>");
		if(subset.containsKey(rs.s("code"))) {
			createList(subset, sb, rs.s("code"), no + 1);
		}
		sb.append("</li>");	
	}
	sb.append("</ul>");
}

%>