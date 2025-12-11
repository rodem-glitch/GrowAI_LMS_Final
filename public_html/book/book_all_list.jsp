<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(0 == userId) { auth.loginForm(); return; }

//객체
LmCategoryDao category = new LmCategoryDao("book");
BookDao book = new BookDao();
BookTargetDao bookTarget = new BookTargetDao();
OrderItemDao orderItem = new OrderItemDao();

//변수
String today = m.time("yyyyMMdd");

//폼입력
int categoryId = m.ri("cid", -1000000 - siteId);

//특정 카테고리가 지정된 경우 하위카테고리 포함 도서 검색
String subIdx = "";
if(categoryId > 0) subIdx = category.getSubIdx(siteId, (m.ri("scid") > 0 ? m.ri("scid") : categoryId));

//장바구니담기
if(m.isPost()) {
	//변수
	String[] bidArr = f.getArr("bid");
	String[] qtyArr = f.getArr("qty");
	Hashtable<String, Integer> cartMap = new Hashtable<String, Integer>();

	//제한
	if(null == bidArr || null == qtyArr) { m.jsAlert(_message.get("alert.book.nodata")); return; }

	//처리
	int cnt = 0;
	for(int i = 0; i < qtyArr.length; i++) {
		int qty = m.parseInt(qtyArr[i]);
		if(qty > 0) {
			if(qty > 1000) qty = 1000;
			cartMap.put(bidArr[i], qty);
			cnt += qty;
		}
	}

	if(1 > cnt) { m.jsAlert(_message.get("alert.order_item.noquantity")); return; }

	//--이전 즉시구매를 일반으로 업데이트
	orderItem.execute(
		"UPDATE " + orderItem.table + " SET "
		+ " status = 10 "
		//+ " WHERE order_id = -99 AND status = 20 AND user_id = " + userId + ""
		+ " WHERE status = 20 AND user_id = " + userId + ""
	);

	//목록
	DataSet blist = book.query(
		" SELECT a.* "
		+ " FROM " + book.table + " a "
		+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.module = 'book' AND c.display_yn = 'Y' "
		+ " WHERE a.book_type = 'R' AND a.site_id = " + siteId + " AND a.display_yn = 'Y' AND a.status = 1 "
		+ (categoryId > 0 ? " AND a.category_id IN (" + (!"".equals(subIdx) ? subIdx : "0") + ") " : "")
		+ " AND (a.target_yn = 'N'"
			+ (!"".equals(userGroups)
				? " OR EXISTS (SELECT 1 FROM " + bookTarget.table + " WHERE book_id = a.id AND group_id IN (" + userGroups + "))"
				: "")
		+ " ) "
		+ " AND a.id IN ('" + m.join("', '", cartMap.keySet().toArray()) + "') "
		+ " ORDER BY a.category_id ASC, a.sort ASC "
	);
	while(blist.next()) {
		int qty = cartMap.get(blist.s("id"));
		if(1 > qty) continue;

		//삭제-이전정보 있는 경우
		DataSet items = orderItem.find("product_type = 'book' AND product_id = " + blist.i("id") + " AND user_id = " + userId + " AND status = 10");
		while(items.next()) {
			orderItem.deleteCartItem(items.i("id"), items.i("coupon_user_id"));
		}

		//과정
		orderItem.item("id", orderItem.getSequence());
		orderItem.item("site_id", siteId);
		orderItem.item("order_id", -99);
		orderItem.item("user_id", userId);
		orderItem.item("product_nm", blist.s("book_nm"));
		orderItem.item("product_type", "book"); //도서
		orderItem.item("product_id", blist.s("id"));
		orderItem.item("course_id", 0);
		orderItem.item("quantity", qty);
		orderItem.item("unit_price", blist.i("book_price"));
		orderItem.item("price", qty * blist.i("book_price"));
		orderItem.item("disc_price", 0);
		orderItem.item("coupon_price", 0);
		orderItem.item("pay_price", qty * blist.i("book_price"));
		orderItem.item("reg_date", m.time("yyyyMMddHHmmss"));
		orderItem.item("status", 10);
		if(!orderItem.insert()) { m.jsAlert(_message.get("alert.order.error_order")); return; }
	}

	//이동
	m.jsAlert(_message.get("alert.order_item.inserted_quantity", new String[] {"cnt=>" + cnt}));
	m.jsReplace("../mypage/cart_list.jsp", "parent");
	return;
}

//목록
DataSet list = book.query(
	" SELECT a.* "
	+ " FROM " + book.table + " a "
	+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.module = 'book' AND c.display_yn = 'Y' "
	+ " WHERE a.book_type = 'R' AND a.site_id = " + siteId + " AND a.display_yn = 'Y' AND a.status = 1 "
	+ (categoryId > 0 ? " AND a.category_id IN (" + (!"".equals(subIdx) ? subIdx : "0") + ") " : "")
	+ " AND (a.target_yn = 'N'"
		+ (!"".equals(userGroups)
			? " OR EXISTS (SELECT 1 FROM " + bookTarget.table + " WHERE book_id = a.id AND group_id IN (" + userGroups + "))"
			: "")
	+ " ) "
	+ " ORDER BY a.category_id ASC, a.sort ASC "
);

//포맷팅
while(list.next()) {
	list.put("book_nm_conv", m.addSlashes(list.s("book_nm")));
	if(!"".equals(list.s("book_img"))) list.put("book_img_url", m.getUploadUrl(list.s("book_img")));
}

DataSet temp = category.getList(siteId, categoryId);
DataSet clist = new DataSet();
while(temp.next()) {
	if(temp.b("display_yn") && 1 == temp.i("status")) clist.addRow(temp.getRow());
}

//출력
p.setLayout(ch);
p.setBody("book.book_all_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,cid"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);

p.setLoop("category_list", clist);
p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));
p.display();

%>