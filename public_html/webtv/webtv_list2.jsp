<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
WebtvDao webtv = new WebtvDao();
WebtvTargetDao webtvTarget = new WebtvTargetDao();
LmCategoryDao category = new LmCategoryDao("webtv");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();

LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

//변수
String today = m.time("yyyyMMdd");

//폼입력
String style = "gallery";
String ord = m.rs("ord");
int categoryId = m.ri("cid", -1000 - siteId);
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 4;

//카테고리가 지정될 경우 카테고리 정보 가져옴.
String pTitle = "전체방송";
DataSet cateInfo = category.find("id = " + categoryId + " AND module = 'webtv'");
if(cateInfo.next()) {
	if(categoryId > 0) pTitle = cateInfo.s("category_nm");
	if(!"".equals(cateInfo.s("list_type"))) style = cateInfo.s("list_type");
	if(!"".equals(cateInfo.s("sort_type"))) ord = "a." + cateInfo.s("sort_type");
//	if(cateInfo.i("list_num") > 0) count = cateInfo.i("list_num");
}
if(categoryId > 0) {
	p.setLoop("categories", category.query(
		" SELECT a.* "
		+ " FROM " + category.table + " a "
		+ " WHERE a.status = 1 AND a.site_id = " + siteId + " AND a.module = 'webtv' AND a.parent_id = " + categoryId
		+ " AND (a.display_yn = 'Y' OR a.depth > 1) "
		+ " AND (a.target_yn = 'N'" //시청대상그룹
		+ (!"".equals(userGroups)
			? " OR EXISTS (SELECT 1 FROM " + categoryTarget.table + " WHERE category_id = a.id AND group_id IN (" + userGroups + "))"
			: "")
		+ " ) "
		+ (1 > userId ? " AND a.LOGIN_YN = 'N' " : "")
		+ " ORDER BY a.sort ASC "
	));
} else if("a.sort ASC".equals(ord)) { ord = "a.allsort ASC"; }

if(!"".equals(m.rs("s_style"))) style = m.rs("s_style");

//폼체크
f.addElement("s_style", style, null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("scid", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(count);
lm.setTable(
	webtv.table + " a INNER JOIN " + category.table + " c ON a.category_id = c.id "
	+ " LEFT JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.status = 1 "
);
lm.setFields("a.*, IF('" + today + "' >= a.open_date, 'Y', 'N') is_open, l.id lesson_id, l.lesson_type, l.start_url, l.content_width, l.content_height, l.short_url ");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.status = 1 AND c.status = 1");
lm.addWhere("a.display_yn = 'Y'");
lm.addWhere("a.open_date <= '" + m.time("yyyyMMddHHmmss") + "'");
lm.addWhere("(a.end_yn = 'N' OR a.end_yn = 'Y' AND a.end_date >= '" + m.time("yyyyMMddHHmmss") + "')");

if(categoryId > 0) { //특정 카테고리가 지정된 경우 하위카테고리 포함 방송 검색
	String subIdx = category.getSubIdx(siteId, m.ri("scid") > 0 ? m.ri("scid") : categoryId);
	lm.addWhere("a.category_id IN (" + (!"".equals(subIdx) ? subIdx : "0") + ")");
}
lm.addWhere( //시청대상그룹
	"(a.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + webtvTarget.table + " WHERE webtv_id = a.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
);
lm.addWhere( //카테고리시청대상그룹
	"(c.target_yn = 'N'" //카테고리시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + categoryTarget.table + " WHERE category_id = c.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
);
if(1 > userId) lm.addWhere("c.LOGIN_YN = 'N'");
lm.addSearch("a.onoff_type", f.get("s_type"));

String sField = f.get("s_field", "");
String allowFields = "a.webtv_nm,a.subtitle,a.keywords,a.content";
if(!m.inArray(sField, allowFields)) sField = "";
if(!"".equals(sField)) lm.addSearch(sField, f.get("s_keyword"), "LIKE");
else lm.addSearch(allowFields, f.get("s_keyword"), "LIKE");
lm.setOrderBy((!"".equals(ord) ? ord : "a.open_date DESC") + ", a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("webtv_nm_conv", m.cutString(list.s("webtv_nm"), 70));
	
	list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
	list.put("subtitle_conv2", m.nl2br(m.stripTags(list.s("subtitle"))));
	list.put("length_conv", m.strrpad(list.s("length_min"), 2, "0") + ":" + m.strrpad(list.s("length_sec"), 2, "0"));

	if(!"".equals(list.s("webtv_file"))) {
		list.put("webtv_file_url", m.getUploadUrl(list.s("webtv_file")));
	} else if("".equals(list.s("webtv_file_url"))) {
		list.put("webtv_file_url", "/common/images/default/noimage_webtv.jpg");
	}

	list.put("content_width_conv", list.i("content_width") + 20);
	list.put("content_height_conv", list.i("content_height") + 23);
	
	list.put("hit_cnt_conv", m.nf(list.i("hit_cnt")));
	list.put("reg_date_conv", m.time(_message.get("format.datetime.dot"), list.s("reg_date")));
	list.put("open_date_conv", m.time(_message.get("format.datetime.dot"), list.s("open_date")));
	list.put("open_day_conv", m.time(_message.get("format.date.dot"), list.s("open_date")));

	String shortUrl = kollus.getPlayUrl(list.s("short_url"), "" + siteId + "_" + loginId, true, 0);
	if("https".equals(request.getScheme())) shortUrl = shortUrl.replace("http://", "https://");
	list.put("short_url", shortUrl);
	list.put("short_url_conv", shortUrl);
}

//목록-카테고리
category.setData(category.getList(siteId));
DataSet parents = category.getParentList(siteId, categoryId);

//출력
p.setLayout(null);
p.setBody("webtv.webtv_list2");
p.setVar("p_title", pTitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);

p.setLoop("parents", parents);
p.setVar("category", cateInfo);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_type", "list".equals(style));
p.setVar("webzine_type", "webzine".equals(style));
p.setVar("gallery_type", "gallery".equals(style));
p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));
p.setVar("style", style);
p.setVar("webtv_type", "webtv");
p.display();

%>