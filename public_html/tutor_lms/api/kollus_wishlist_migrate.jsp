<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 기존 "레슨 찜"(module=lesson)은 숫자 lesson_id 기준이라 콜러스 찜으로 바로 표시되지 않습니다.
//- 콜러스 레슨(lesson_type=05/07)을 매핑 테이블로 옮겨 "module=kollus" 찜으로 변환합니다.

if(!isAdmin) {
	result.put("rst_code", "4030");
	result.put("rst_message", "관리자 권한이 필요합니다.");
	result.print();
	return;
}

KollusMediaDao kollusMedia = new KollusMediaDao();
WishlistDao wishlist = new WishlistDao(siteId);
LessonDao lesson = new LessonDao();

DataSet list = wishlist.query(
	" SELECT w.user_id, w.reg_date, l.start_url media_key, l.lesson_nm title "
	+ " FROM " + wishlist.table + " w "
	+ " INNER JOIN " + lesson.table + " l ON w.module_id = l.id "
	+ " WHERE w.site_id = " + siteId + " AND w.module = 'lesson' "
	+ " AND l.site_id = " + siteId + " AND l.status != -1 "
	+ " AND l.lesson_type IN ('05','07') "
);

int inserted = 0;
int skipped = 0;
while(list.next()) {
	String mediaKey = list.s("media_key");
	if("".equals(mediaKey)) { skipped++; continue; }

	DataSet minfo = kollusMedia.find(
		"site_id = " + siteId + " AND media_content_key = ?",
		new String[] { mediaKey }
	);
	int mediaId = 0;
	if(minfo.next()) {
		mediaId = minfo.i("id");
	} else {
		mediaId = kollusMedia.getSequence();
		kollusMedia.item("id", mediaId);
		kollusMedia.item("site_id", siteId);
		kollusMedia.item("media_content_key", mediaKey);
		kollusMedia.item("title", list.s("title"));
		kollusMedia.item("snapshot_url", "");
		kollusMedia.item("category_key", "");
		kollusMedia.item("category_nm", "");
		kollusMedia.item("original_file_name", "");
		kollusMedia.item("total_time", 0);
		kollusMedia.item("content_width", 0);
		kollusMedia.item("content_height", 0);
		kollusMedia.item("reg_date", m.time("yyyyMMddHHmmss"));
		kollusMedia.item("mod_date", m.time("yyyyMMddHHmmss"));
		if(!kollusMedia.insert()) { skipped++; continue; }
	}

	if(wishlist.isAdded(list.i("user_id"), "kollus", mediaId)) {
		skipped++;
		continue;
	}

	wishlist.item("user_id", list.i("user_id"));
	wishlist.item("module", "kollus");
	wishlist.item("module_id", mediaId);
	wishlist.item("site_id", siteId);
	wishlist.item("reg_date", list.s("reg_date"));
	if(wishlist.insert()) inserted++;
	else skipped++;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_inserted", inserted);
result.put("rst_skipped", skipped);
result.print();

%>
