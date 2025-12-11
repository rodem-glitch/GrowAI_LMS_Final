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
String idx = m.rs("idx");
String bidx = m.rs("bidx");
if("".equals(type) || ("".equals(idx) && "".equals(bidx))) { m.jsAlert(_message.get("alert.common.required_key")); return; }
idx = "'" + m.replace(idx, ",", "','") + "'";
bidx = "'" + m.replace(bidx, ",", "','") + "'";

//변수
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CoursePrecedeDao coursePrecede = new CoursePrecedeDao();
CoursePackageDao coursePackage = new CoursePackageDao();
BookDao book = new BookDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
MailDao mail = new MailDao();

//과정정보
DataSet clist = course.query(
	"SELECT a.* "
	+ ", (CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' ELSE 'N' "
	+ " END) is_request "
	+ " FROM " + course.table + " a "
	+ " WHERE a.id IN (" + idx + ") AND a.sale_yn = 'Y' AND a.status = 1 AND a.site_id = " + siteId + ""
);

//도서정보
DataSet blist = book.query(
	"SELECT a.* "
	+ " FROM " + book.table + " a "
	+ " WHERE a.id IN (" + bidx + ") AND a.status = 1 AND a.site_id = " + siteId + " "
);

//장바구니 담기
//--이전 즉시구매를 일반으로 업데이트
orderItem.execute(
	"UPDATE " + orderItem.table + " SET status = 10, order_id = -99 "
	//+ " WHERE order_id = -99 AND status = 20 AND user_id = " + userId + ""
	+ " WHERE status = 20 AND user_id = " + userId + ""
);

//삭제-이전정보
DataSet items = orderItem.find("course_id IN ( " + idx + " ) AND user_id = " + userId + " AND status = 10");
while(items.next()) {
	orderItem.deleteCartItem(items.i("id"), items.i("coupon_user_id"));
}

//변수
int newOrderId = "D".equals(type) ? order.getSequence() : -99;

//담기-과정
while(clist.next()) {
	orderItem.item("id", orderItem.getSequence());
	orderItem.item("site_id", siteId);
	orderItem.item("order_id", newOrderId);
	orderItem.item("user_id", userId);
	orderItem.item("product_nm", clist.s("course_nm"));
	orderItem.item("product_type", "course"); //과정
	orderItem.item("product_id", clist.i("id"));
	orderItem.item("course_id", clist.i("id"));
	orderItem.item("quantity", 1);
	orderItem.item("unit_price", clist.i("price"));
	orderItem.item("price", clist.i("price"));
	orderItem.item("disc_price", 0);
	orderItem.item("coupon_price", 0);
	orderItem.item("pay_price", clist.i("price"));
	orderItem.item("reg_date", now);
	orderItem.item("status", "D".equals(type) ? 20 : 10);
	if(!orderItem.insert()) { m.jsAlert(_message.get("alert.order_item.error_insert")); return; }
}

//담기-도서
while(blist.next()) {
	orderItem.item("id", orderItem.getSequence());
	orderItem.item("site_id", siteId);
	orderItem.item("order_id", newOrderId);
	orderItem.item("user_id", userId);
	orderItem.item("product_nm", blist.s("book_nm"));
	orderItem.item("product_type", "book"); //도서
	orderItem.item("product_id", blist.i("id"));
	orderItem.item("course_id", 0);
	orderItem.item("quantity", 1);
	orderItem.item("unit_price", blist.i("book_price"));
	orderItem.item("price", blist.i("book_price"));
	orderItem.item("disc_price", 0);
	orderItem.item("coupon_price", 0);
	orderItem.item("pay_price", blist.i("book_price"));
	orderItem.item("reg_date", now);
	orderItem.item("status", "D".equals(type) ? 20 : 10);
	if(!orderItem.insert()) { m.jsAlert(_message.get("alert.order_item.error_insert")); return; }
}

//이동
if("D".equals(type)) {	
	//세션
	mSession.put("last_order_id", newOrderId);
	mSession.save();

	m.jsReplace("../order/payment.jsp?oek=" + order.getOrderEk(newOrderId, userId), "parent");
} else {
	m.jsReplace("../mobile/cart_list.jsp", "parent");
}
return;

%>