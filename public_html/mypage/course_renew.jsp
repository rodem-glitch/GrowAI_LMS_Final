<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { m.jsAlert(_message.get("alert.member.required_login")); return; }

//폼입력
int cuid = m.ri("cuid");
if(cuid == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

//변수
String today = m.time("yyyyMMdd");

//정보
DataSet info = courseUser.query(
	"SELECT a.*, c.id course_id, c.course_nm, c.course_type, c.onoff_type, c.lesson_day, c.renew_price, c.renew_yn, oi.renew_id "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + orderItem.table + " oi ON a.id = oi.renew_id AND oi.status = 2 "
	+ " WHERE a.id = ? AND a.user_id = " + userId + " AND a.status IN (1, 3) "
	+ " AND '" + today + "' BETWEEN a.start_date AND a.end_date "
	, new Integer[] { cuid }
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//제한-진행중주문
if(0 < info.i("renew_id")) {
	m.jsError(_message.get("alert.order_item.extend_progress"));
	return;
}

//제한
if(!info.b("renew_yn") || !"A".equals(info.s("course_type")) || !"N".equals(info.s("onoff_type")) || (0 > m.diffDate("D", today, info.s("end_date")))) {
	m.jsError(_message.get("alert.course.noextend"));
	return;
}

//변수
int cid = info.i("course_id");

//장바구니 담기
//--이전 즉시구매를 일반으로 업데이트
orderItem.execute("UPDATE " + orderItem.table + " SET status = 10, order_id = -99 WHERE status = 20 AND user_id = " + userId);

//삭제-이전정보 있는 경우
DataSet items = orderItem.find("course_id = " + cid + " AND user_id = " + userId + " AND status = 10");
while(items.next()) {
	orderItem.deleteCartItem(items.i("id"), items.i("coupon_user_id"));
}

//과정
int newId = orderItem.getSequence();
int newOrderId = order.getSequence();
orderItem.item("id", newId);
orderItem.item("site_id", siteId);
orderItem.item("order_id", newOrderId);
orderItem.item("user_id", userId);
orderItem.item("product_nm", "[" + _message.get("course.extend.prefix") + m.time(_message.get("format.date.dot"), m.addDate("D", info.i("lesson_day"), info.s("end_date"))) + _message.get("course.extend.suffix") + "] " + info.s("course_nm"));
orderItem.item("product_type", "c_renew"); //과정
orderItem.item("product_id", cid);
orderItem.item("course_id", cid);
orderItem.item("renew_yn", "Y");
orderItem.item("renew_id", cuid);
orderItem.item("quantity", 1);
orderItem.item("unit_price", info.i("renew_price"));
orderItem.item("price", info.i("renew_price"));
orderItem.item("disc_price", 0);
orderItem.item("coupon_price", 0);
orderItem.item("pay_price", info.i("renew_price"));
orderItem.item("reg_date", m.time("yyyyMMddHHmmss"));
orderItem.item("status", 20);
if(!orderItem.insert()) { m.jsAlert(_message.get("alert.course_user.error_enroll")); return; }

//세션
mSession.put("last_order_id", newOrderId);
mSession.save();

//이동
m.jsReplace("../order/payment.jsp?oek=" + order.getOrderEk(newOrderId, userId), "parent");

%>