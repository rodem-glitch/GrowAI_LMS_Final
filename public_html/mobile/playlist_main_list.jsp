<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int cid = m.ri("cid");
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 100;
boolean isRand = "Y".equals(m.rs("rand"));

String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");

//객체
WebtvDao webtv = new WebtvDao();
WebtvTargetDao webtvTarget = new WebtvTargetDao();
WebtvPlaylistDao webtvPlaylist = new WebtvPlaylistDao();
LmCategoryDao category = new LmCategoryDao("webtv_playlist");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();

//기본키
int categoryId = m.ri("cid");
if(0 == categoryId) return;
String subIdx = category.getSubIdx(siteId, categoryId);

//정보
DataSet info = category.find("id = ? AND site_id = " + siteId + " AND display_yn = 'Y' AND status = 1", new Object[] {categoryId});
if(!info.next()) return;

//목록
//webtv.d(out);
DataSet list = webtv.query(
	" SELECT a.*, IF('" + now + "' >= a.open_date, 'Y', 'N') is_open, p.category_id playlist_id, pc.parent_id parent_playlist_id, c.parent_id "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + webtvPlaylist.table + " p ON a.id = p.webtv_id "
	+ " INNER JOIN " + category.table + " pc ON p.category_id = pc.id AND pc.status = 1 "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 1 AND a.display_yn = 'Y' "
	+ " AND p.category_id IN (" + subIdx + ") "
	+ " AND a.open_date <= '" + m.time("yyyyMMddHHmmss") + "'"
	+ " AND (pc.target_yn = 'N' " //카테고리시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + categoryTarget.table + " WHERE category_id = pc.id AND group_id IN (" + userGroups + ")) "
		: "")
	+ " ) "
	+ (1 > userId ? " AND pc.login_yn = 'N' " : "")
	+ " ORDER BY " + (!isRand ? " p.sort asc " : " RAND() ")
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
}

//출력
p.setLayout(null);
p.setBody("mobile.playlist_main_list");

p.setLoop("list", list);
p.setVar("playlist_" + cid, true);
p.display();

%>