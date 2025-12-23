<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 콜러스 media_content_key(문자열)를 숫자 ID로 매핑해 TB_WISHLIST에 저장해야 합니다.
//- 이미 있으면 재사용하고, 없으면 TB_KOLLUS_MEDIA에 생성합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

String mediaKey = m.rs("media_content_key").trim();
String title = m.rs("title").trim();
String snapshotUrl = m.rs("snapshot_url").trim();
String categoryKey = m.rs("category_key").trim();
String categoryNm = m.rs("category_nm").trim();
String originalFileName = m.rs("original_file_name").trim();
int totalTime = m.ri("total_time");
int contentWidth = m.ri("content_width");
int contentHeight = m.ri("content_height");

if("".equals(mediaKey)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "media_content_key가 필요합니다.");
	result.print();
	return;
}

KollusMediaDao kollusMedia = new KollusMediaDao();
WishlistDao wishlist = new WishlistDao(siteId);

DataSet info = kollusMedia.find(
	"site_id = " + siteId + " AND media_content_key = ?",
	new String[] { mediaKey }
);

int mediaId = 0;
if(info.next()) {
	mediaId = info.i("id");
	kollusMedia.item("title", title);
	kollusMedia.item("snapshot_url", snapshotUrl);
	kollusMedia.item("category_key", categoryKey);
	kollusMedia.item("category_nm", categoryNm);
	kollusMedia.item("original_file_name", originalFileName);
	kollusMedia.item("total_time", totalTime);
	kollusMedia.item("content_width", contentWidth);
	kollusMedia.item("content_height", contentHeight);
	kollusMedia.item("mod_date", m.time("yyyyMMddHHmmss"));
	kollusMedia.update("id = " + mediaId);
} else {
	mediaId = kollusMedia.getSequence();
	kollusMedia.item("id", mediaId);
	kollusMedia.item("site_id", siteId);
	kollusMedia.item("media_content_key", mediaKey);
	kollusMedia.item("title", !"".equals(title) ? title : ("콜러스 " + mediaKey));
	kollusMedia.item("snapshot_url", snapshotUrl);
	kollusMedia.item("category_key", categoryKey);
	kollusMedia.item("category_nm", categoryNm);
	kollusMedia.item("original_file_name", originalFileName);
	kollusMedia.item("total_time", totalTime);
	kollusMedia.item("content_width", contentWidth);
	kollusMedia.item("content_height", contentHeight);
	kollusMedia.item("reg_date", m.time("yyyyMMddHHmmss"));
	kollusMedia.item("mod_date", m.time("yyyyMMddHHmmss"));
	if(!kollusMedia.insert()) {
		result.put("rst_code", "2000");
		result.put("rst_message", "매핑 정보 저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
}

int toggled = wishlist.toggle(userId, "kollus", mediaId);
if(toggled < 0) {
	result.put("rst_code", "2001");
	result.put("rst_message", "찜 처리 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", toggled);
result.print();

%>
