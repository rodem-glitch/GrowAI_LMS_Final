<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 차시 구성에서 "콘텐츠(레슨) 검색" 모달은 실제 레슨(LM_LESSON) 목록을 보여줘야 합니다.
//- 즐겨찾기(찜)는 TB_WISHLIST로 저장/조회합니다.

LessonDao lesson = new LessonDao();
WishlistDao wishlist = new WishlistDao(siteId);

String keyword = m.rs("s_keyword");
String favoriteYn = m.rs("favorite_yn"); //Y면 찜한 것만

ArrayList<Object> params = new ArrayList<Object>();
String where = " a.site_id = " + siteId + " AND a.status = 1 AND a.use_yn = 'Y' ";

if(!"".equals(keyword)) {
	where += " AND (a.lesson_nm LIKE ? OR a.description LIKE ?) ";
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
}

String joinWish = "";
if("Y".equalsIgnoreCase(favoriteYn)) {
	joinWish = " INNER JOIN " + wishlist.table + " w ON w.user_id = " + userId + " AND w.site_id = " + siteId + " AND w.module = 'lesson' AND w.module_id = a.id ";
}

DataSet list = lesson.query(
	" SELECT a.id, a.lesson_nm title, a.description, a.lesson_type, a.total_time, a.reg_date "
	+ " , (SELECT COUNT(*) FROM " + wishlist.table + " w "
		+ " WHERE w.user_id = " + userId + " AND w.site_id = " + siteId + " AND w.module = 'lesson' AND w.module_id = a.id) is_favorite "
	+ " FROM " + lesson.table + " a "
	+ joinWish
	+ " WHERE " + where
	+ " ORDER BY a.id DESC "
	, params.toArray()
);

while(list.next()) {
	list.put("id", list.i("id"));
	list.put("title", list.s("title"));
	list.put("is_favorite", list.i("is_favorite") > 0);
	list.put("duration", list.i("total_time") > 0 ? (list.i("total_time") + "분") : "-");
	//왜: 썸네일/태그/조회수는 현재 레슨 테이블에 없어서, 화면에서는 기본값으로 처리합니다.
	list.put("thumbnail", "");
	list.put("views", 0);
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

