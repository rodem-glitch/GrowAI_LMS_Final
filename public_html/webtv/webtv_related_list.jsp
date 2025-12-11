<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 4;

//변수
String now = m.time("yyyyMMddHHmmss");

//객체
WebtvDao webtv = new WebtvDao();
WebtvTargetDao webtvTarget = new WebtvTargetDao();
LmCategoryDao category = new LmCategoryDao("webtv");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();

//목록
DataSet list = webtv.query(
	" SELECT a.*, c.parent_id "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 1 AND a.display_yn = 'Y' "
	+ " AND a.open_date <= '" + now + "' "
	+ " AND (a.target_yn = 'N' " //시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + webtvTarget.table + " WHERE webtv_id = a.id AND group_id IN (" + userGroups + ")) "
		: "")
	+ " ) "
	+ " AND (c.target_yn = 'N' " //카테고리시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + categoryTarget.table + " WHERE category_id = c.id AND group_id IN (" + userGroups + ")) "
		: "")
	+ " ) "
	+ (1 > userId ? " AND c.login_yn = 'N' " : "")
	+ " ORDER BY a.open_date DESC, a.id DESC "
	, count
);
while(list.next()) {
	list.put("webtv_nm_conv", m.cutString(list.s("webtv_nm"), 70));
	
	list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
	list.put("length_conv", m.strpad(list.s("length_min"), 2, "0") + ":" + m.strpad(list.s("length_sec"), 2, "0"));

	if(!"".equals(list.s("webtv_file"))) {
		list.put("webtv_file_url", m.getUploadUrl(list.s("webtv_file")));
	} else if("".equals(list.s("webtv_file_url"))) {
		list.put("webtv_file_url", "/common/images/default/noimage_webtv.jpg");
	}

	list.put("open_date_conv", m.time(_message.get("format.datetime.dot"), list.s("open_date")));
}

//출력
p.setLayout(null);
p.setBody("main.webtv_recent_list");

p.setLoop("list", list);
p.display();

%>