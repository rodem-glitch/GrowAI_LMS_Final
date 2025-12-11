<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(0 == userId) { m.redirect("login.jsp"); return; }

//정보-회원
UserDao user = new UserDao();
DataSet uinfo = user.find("id = " + userId + " AND status = 1");
if(!uinfo.next()) { m.jsError(_message.get("alert.member.nodata")); return; }
uinfo.put("mobile", !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "");

//기본키
String type = m.rs("type");
int id = m.ri("id");
int qty = m.ri("qty");
if("".equals(type) || id == 0) { m.jsAlert(_message.get("alert.common.required_key")); return; }
if(qty == 0) qty = 1;

//객체
BookDao book = new BookDao();
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

//도서정보
DataSet info = book.query(
	"SELECT a.* "
	+ " FROM " + book.table + " a "
	+ " WHERE a.id = " + id + " AND a.status = 1 AND a.site_id = " + siteId + " "
);
if(!info.next()) { m.jsAlert(_message.get("alert.book.nodata")); return; }

//장바구니확인 - 장바구니/cnf=N
if("G".equals(m.rs("type")) && !"Y".equals(m.rs("cnf"))) {
	out.print("<script>if(confirm('장바구니에 담으시겠습니까?')) location.href = '../mobile/cart_book_insert.jsp?cnf=Y&" + m.qs("cnf") + "';</script>");
} else {
	//장바구니 담기
	//--이전 즉시구매를 일반으로 업데이트
	orderItem.execute(
		"UPDATE " + orderItem.table + " SET "
		+ " status = 10, order_id = -99 "
		//+ " WHERE order_id = -99 AND status = 20 AND user_id = " + userId + ""
		+ " WHERE status = 20 AND user_id = " + userId + ""
	);

	Vector<String> v = new Vector<String>(); //Rollback

	//삭제-이전정보 있는 경우
	DataSet items = orderItem.find("product_type = 'book' AND product_id = " + id + " AND user_id = " + userId + " AND status = 10");
	while(items.next()) {
		orderItem.deleteCartItem(items.i("id"), items.i("coupon_user_id"));
	}

	//변수
	int newOrderId = "D".equals(type) ? order.getSequence() : -99;

	//과정
	int newId = orderItem.getSequence(); v.add("" + newId);
	orderItem.item("id", newId);
	orderItem.item("site_id", siteId);
	orderItem.item("order_id", newOrderId);
	orderItem.item("user_id", userId);
	orderItem.item("product_nm", info.s("book_nm"));
	orderItem.item("product_type", "book"); //도서
	orderItem.item("product_id", id);
	orderItem.item("course_id", 0);
	orderItem.item("quantity", qty);
	orderItem.item("unit_price", info.i("book_price"));
	orderItem.item("price", info.i("book_price") * qty);
	orderItem.item("disc_price", 0);
	orderItem.item("coupon_price", 0);
	orderItem.item("pay_price", info.i("book_price") * qty);
	orderItem.item("reg_date", m.time("yyyyMMddHHmmss"));
	orderItem.item("status", "D".equals(type) ? 20 : 10);
	if(!orderItem.insert()) { m.jsAlert(_message.get("alert.order.error_order")); return; }

	if("D".equals(type)) {
		//바로구매시 결제페이지로
		//세션
		mSession.put("last_order_id", newOrderId);
		mSession.save();

		out.print("<script>if(confirm('주문하시겠습니까?')) parent.location.href ='../order/payment.jsp?oek=" + order.getOrderEk(newOrderId, userId) + "';</script>");
	} else {
		//아니면 장바구니로
		//out.print("<script>if(confirm('장바구니를 확인하시겠습니까?')) parent.location.href ='../mobile/cart_list.jsp';</script>");
		out.print("<script>if(confirm('장바구니를 확인하시겠습니까?')) parent.location.href ='../order/cart_list.jsp';</script>"); //vzone 모바일 도서 장바구니
	}

}

%>