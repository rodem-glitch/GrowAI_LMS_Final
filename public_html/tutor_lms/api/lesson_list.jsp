<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 차시 구성에서 "콘텐츠(레슨) 검색" 모달은 실제 레슨(LM_LESSON) 목록을 보여줘야 합니다.
//- 즐겨찾기(찜)는 TB_WISHLIST로 저장/조회합니다.

LessonDao lesson = new LessonDao();
WishlistDao wishlist = new WishlistDao(siteId);
ContentDao content = new ContentDao();

String keyword = m.rs("s_keyword");
String favoriteYn = m.rs("favorite_yn"); //Y면 찜한 것만
String lessonType = m.rs("lesson_type"); //콘텐츠타입 필터
int contentId = m.ri("content_id"); //콘텐츠 묶음 필터

ArrayList<Object> params = new ArrayList<Object>();
String where = " a.site_id = " + siteId + " AND a.status = 1 AND a.use_yn = 'Y' ";

if(!"".equals(keyword)) {
	where += " AND (a.lesson_nm LIKE ? OR a.description LIKE ?) ";
	params.add("%" + keyword + "%");
	params.add("%" + keyword + "%");
}

//콘텐츠타입 필터
if(!"".equals(lessonType)) {
	where += " AND a.lesson_type = ? ";
	params.add(lessonType);
}

//콘텐츠 묶음 필터
if(contentId > 0) {
	where += " AND a.content_id = " + contentId + " ";
}

String joinWish = "";
if("Y".equalsIgnoreCase(favoriteYn)) {
	joinWish = " INNER JOIN " + wishlist.table + " w ON w.user_id = " + userId + " AND w.site_id = " + siteId + " AND w.module = 'lesson' AND w.module_id = a.id ";
}

DataSet list = lesson.query(
	" SELECT a.id, a.lesson_nm title, a.description, a.lesson_type, a.total_time, a.complete_time, a.reg_date, a.content_id "
	+ " , c.content_nm "
	+ " , (SELECT COUNT(*) FROM " + wishlist.table + " w "
		+ " WHERE w.user_id = " + userId + " AND w.site_id = " + siteId + " AND w.module = 'lesson' AND w.module_id = a.id) is_favorite "
	+ " FROM " + lesson.table + " a "
	+ " LEFT JOIN " + content.table + " c ON c.id = a.content_id AND c.status = 1 "
	+ joinWish
	+ " WHERE " + where
	+ " ORDER BY a.id DESC "
	, params.toArray()
);

while(list.next()) {
	list.put("id", list.i("id"));
	list.put("title", list.s("title"));
	list.put("is_favorite", list.i("is_favorite") > 0);
	list.put("total_time", list.i("total_time"));
	list.put("complete_time", list.i("complete_time"));
	list.put("duration", list.i("total_time") > 0 ? (list.i("total_time") + "분") : "-");
	list.put("content_nm", list.s("content_nm"));
	//왜: lesson_type은 코드(01/02/03...)라서, 화면에서는 사람이 읽을 수 있는 라벨도 같이 내려줍니다.
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allTypes));
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
