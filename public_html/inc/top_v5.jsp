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

// [중요] 과정 카테고리 ↔ 상단 메뉴 연동
// - sysop의 과정카테고리(= LM_CATEGORY)를 수정하면, 프론트 상단/모바일 메뉴도 같이 바뀌는 게 자연스럽습니다.
// - 그런데 현재 사용 중인 `top_v5.html`(커스텀 헤더)에는 과정 메뉴 링크(`cid=...`)와 문구가 하드코딩되어 있어서,
//   카테고리를 추가/삭제/이름변경/정렬해도 프론트 메뉴가 절대 자동으로 맞춰지지 않습니다.
// - 그래서 여기서 DB 카테고리를 읽어서, 템플릿에 그대로 꽂아 넣을 수 있는 HTML 조각을 만들어 내려줍니다.
DataSet courseCats = category.find(
	"module = 'course' AND depth IN (1, 2) AND display_yn = 'Y' AND status = 1 AND site_id = " + siteId
	, "id, parent_id, category_nm, depth, sort"
	, "depth ASC, parent_id ASC, sort ASC"
);

DataSet courseDepth1 = new DataSet();
HashMap<Integer, DataSet> courseChildrenMap = new HashMap<Integer, DataSet>();
while(courseCats.next()) {
	int depth = courseCats.i("depth");
	if(depth == 1) {
		courseDepth1.addRow(courseCats.getRow());
	} else if(depth == 2) {
		int parentId = courseCats.i("parent_id");
		if(!courseChildrenMap.containsKey(parentId)) courseChildrenMap.put(parentId, new DataSet());
		courseChildrenMap.get(parentId).addRow(courseCats.getRow());
	}
}
courseDepth1.first();

StringBuilder courseMainMenuBefore = new StringBuilder();
StringBuilder courseMainMenuAfter = new StringBuilder();
StringBuilder courseMobileMenuBefore = new StringBuilder();
StringBuilder courseMobileMenuAfter = new StringBuilder();

int courseTopIndex = 0;
while(courseDepth1.next()) {
	courseTopIndex++;
	int categoryId = courseDepth1.i("id");
	String categoryName = courseDepth1.s("category_nm");
	String categoryCh = "course" + categoryId;

	StringBuilder mainItem = new StringBuilder();
	mainItem.append("<li><a href=\"/course/course_list.jsp?cid=");
	mainItem.append(categoryId);
	mainItem.append("&ch=");
	mainItem.append(categoryCh);
	mainItem.append("\" target=\"_self\">");
	mainItem.append(categoryName);
	mainItem.append("</a></li>\n");

	DataSet children = courseChildrenMap.get(categoryId);
	boolean hasChildren = (children != null && children.size() > 0);

	StringBuilder mobileItem = new StringBuilder();
	if(hasChildren) {
		mobileItem.append("<li class=\"li-sub-menu\"><a href=\"#none\" target=\"_self\">");
		mobileItem.append(categoryName);
		mobileItem.append("\n");
		mobileItem.append("    <span class=\"line\"></span>\n");
		mobileItem.append("    <span class=\"line1\"></span>\n");
		mobileItem.append("</a>\n");
		mobileItem.append("    <ul class=\"util_toggle_btn-menu-in\">\n");
		mobileItem.append("        <li><a href=\"/course/course_list.jsp?cid=");
		mobileItem.append(categoryId);
		mobileItem.append("&ch=");
		mobileItem.append(categoryCh);
		mobileItem.append("\" target=\"_self\">전체</a></li>\n");

		children.first();
		while(children.next()) {
			mobileItem.append("        <li><a href=\"/course/course_list.jsp?cid=");
			mobileItem.append(children.i("id"));
			mobileItem.append("&ch=");
			// 하위 카테고리에서도 '상위 카테고리 전용 레이아웃'을 그대로 쓰고 싶을 때가 많아서
			// ch는 상위(1depth) 카테고리 기준으로 유지합니다.
			mobileItem.append(categoryCh);
			mobileItem.append("\" target=\"_self\">");
			mobileItem.append(children.s("category_nm"));
			mobileItem.append("</a></li>\n");
		}
		mobileItem.append("    </ul>\n");
		mobileItem.append("</li>\n");
	} else {
		mobileItem.append("<li><a href=\"/course/course_list.jsp?cid=");
		mobileItem.append(categoryId);
		mobileItem.append("&ch=");
		mobileItem.append(categoryCh);
		mobileItem.append("\" target=\"_self\">");
		mobileItem.append(categoryName);
		mobileItem.append("</a></li>\n");
	}

	// 디자인상 'VIRTUAL CLASS'를 2번째에 고정해두고 싶어서,
	// 첫 번째 과정 카테고리만 Before에 두고 나머지는 After로 분리합니다.
	if(courseTopIndex == 1) {
		courseMainMenuBefore.append(mainItem);
		courseMobileMenuBefore.append(mobileItem);
	} else {
		courseMainMenuAfter.append(mainItem);
		courseMobileMenuAfter.append(mobileItem);
	}
}

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
p.setVar("course_main_menu_before_html", courseMainMenuBefore.toString());
p.setVar("course_main_menu_after_html", courseMainMenuAfter.toString());
p.setVar("course_mobile_menu_before_html", courseMobileMenuBefore.toString());
p.setVar("course_mobile_menu_after_html", courseMobileMenuAfter.toString());
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
