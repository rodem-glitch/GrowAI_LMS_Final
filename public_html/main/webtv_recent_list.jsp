<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
boolean isRecomm = "Y".equals(m.rs("recomm"));
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 4;
int cid = m.ri("cid");
int line = m.ri("line") > 0 ? m.ri("line") : 100;

//변수
String now = m.time("yyyyMMddHHmmss");

//객체
WebtvDao webtv = new WebtvDao();
WebtvTargetDao webtvTarget = new WebtvTargetDao();
LmCategoryDao category = new LmCategoryDao("webtv");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();

FileDao file = new FileDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

//목록
DataSet list = webtv.query(
	" SELECT a.*, c.parent_id, l.lesson_type, l.start_url "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.status = 1 "
	+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 1 AND a.display_yn = 'Y' "
	+ " AND a.open_date <= '" + now + "' "
	+ (isRecomm ? " AND a.recomm_yn = 'Y' " : "")
	+ " AND a.open_date <= '" + m.time("yyyyMMddHHmmss") + "'"
	+ " AND (a.end_yn = 'N' OR a.end_yn = 'Y' AND a.end_date >= '" + m.time("yyyyMMddHHmmss") + "') "
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
	+ (0 < cid ? " AND a.category_id IN (" + category.getSubIdx(siteId, cid) + ") " : "")
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

	list.put("content_width_conv", list.i("content_width") + 20);
	list.put("content_height_conv", list.i("content_height") + 23);
	
	list.put("open_date_conv", m.time(_message.get("format.datetime.dot"), list.s("open_date")));
	list.put("start_url_conv", "05".equals(list.s("lesson_type")) ? kollus.getPlayUrl(list.s("start_url"), "" + siteId + "_" + loginId, true, 0) : list.s("start_url"));
		
	//동영상경로보안
	if("01".equals(list.s("lesson_type")) || "03".equals(list.s("lesson_type"))) {
		int lid = list.i("lesson_id");
		int unixTime = m.getUnixTime();
		String key = lid + "|" + userId + "|" + unixTime;
		String startUrl = "/main/video.jsp?ek=" + m.encrypt(key) + "&lid=" + lid + "&uid=" + userId + "&ut=" + unixTime;
		list.put("start_url", startUrl);
		list.put("start_url_conv", "/player/webtvplayer.jsp?lid=" + lid + "&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd")));
	}
	list.put("class", list.i("__ord") % line == 1 ? "first" : "");
}

//출력
p.setLayout(null);
p.setBody("main.webtv_recent_list");

p.setLoop("list", list);
p.display();

%>