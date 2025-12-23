<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- TB_WISHLIST에 저장된 콜러스 찜 목록을 실제 카드 목록으로 내려줘야 합니다.

KollusMediaDao kollusMedia = new KollusMediaDao();
WishlistDao wishlist = new WishlistDao(siteId);

String keyword = m.rs("s_keyword");
int pg = m.ri("page") > 0 ? m.ri("page") : 1;
int limit = m.ri("limit") > 0 ? m.ri("limit") : 20;
if(limit > 200) limit = 200;

try {
	ListManager lm = new ListManager();
	lm.setRequest(request);
	lm.setListNum(limit);
	//왜: ListManager는 request의 page 파라미터를 사용하며, setPageNum 메소드는 없습니다.
	lm.setTable(wishlist.table + " w INNER JOIN " + kollusMedia.table + " m ON w.module_id = m.id");
	lm.setFields("w.module_id, w.reg_date, m.media_content_key, m.title, m.snapshot_url, m.category_key, m.category_nm, m.original_file_name, m.total_time, m.content_width, m.content_height");
	lm.addWhere("w.site_id = " + siteId);
	lm.addWhere("w.user_id = " + userId);
	lm.addWhere("w.module = 'kollus'");
	lm.addWhere("m.site_id = " + siteId);
	if(!"".equals(keyword)) lm.addWhere("m.title LIKE '%" + keyword + "%'");
	lm.setOrderBy("w.reg_date DESC");

	DataSet list = lm.getDataSet();
	while(list.next()) {
		list.put("id", list.i("module_id"));
		list.put("thumbnail", list.s("snapshot_url"));
		list.put("is_favorite", true);
	}

	result.put("rst_code", "0000");
	result.put("rst_message", "성공");
	result.put("rst_total", lm.getTotalNum());
	result.put("rst_page", pg);
	result.put("rst_limit", limit);
	result.put("rst_data", list);
	result.print();
} catch(Exception ex) {
	//왜: 오류가 나도 JSON 응답은 유지해야 프론트에서 파싱 오류가 나지 않습니다.
	m.errorLog("tutor_lms.kollus_wishlist_list error - " + ex.getMessage(), ex);
	result.put("rst_code", "5000");
	result.put("rst_message", "찜 목록 조회 중 오류가 발생했습니다.");
	result.print();
}

%>
