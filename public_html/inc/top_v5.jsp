<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
LmCategoryDao category = new LmCategoryDao();
SitemapDao sitemap = new SitemapDao();
HashMap<String, DataSet> subset = new HashMap<String, DataSet>();
UserLoginDao userLogin = new UserLoginDao();

//목록
DataSet _rs = sitemap.find(
	"site_id = " + siteId + " AND code != 'member'"
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

StringBuilder sb = new StringBuilder();
createList(subset, sb, "_root_", 1);

//최근로그인시간
DataSet ullist = userLogin.find("site_id = " + siteId + " AND user_id = " + userId + " AND login_type = 'I'", "reg_date", "reg_date DESC");
int cnt = 1;
String recentLoginTime = "";
while (ullist.next()){
	if(cnt == 2){
		recentLoginTime = m.time("yyyy.MM.dd HH:mm:ss", ullist.s("reg_date"));
		break;
	}
	cnt++;
}

p.setLayout(null);
p.setBody("layout.top_v5");
p.setVar("gnb_menu", sb.toString());
p.setVar("recent_login_time", !"".equals(recentLoginTime)? recentLoginTime : "없음");
p.setLoop("top_menu", list);
p.display();

%><%!

public void createList(HashMap<String, DataSet> subset, StringBuilder sb, String pcode, int no) {
	DataSet rs = subset.get(pcode);
	rs.first();
	sb.append("<ul ");
	if(no == 1) sb.append("id='gnb' ");
	sb.append("class='depth");
	sb.append(Integer.toString(no));
	sb.append("'>");
	while(rs.next()) {
		sb.append("<li id='gnb_");
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