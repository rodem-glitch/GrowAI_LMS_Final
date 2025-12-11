<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseDao course = new CourseDao();
BookDao book = new BookDao();
FreepassDao freepass = new FreepassDao();
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
GroupDao group = new GroupDao();

//갱신-결제대기에서 카트로 옮김
//orderItem.execute("UPDATE " + orderItem.table + " SET status = 10 WHERE order_id = -99 AND status = 20 AND user_id = " + userId);
orderItem.execute("UPDATE " + orderItem.table + " SET order_id = -99, status = 10 WHERE status = 20 AND user_id = " + userId);

//변수
String today = m.time("yyyyMMdd");
boolean isReload = false;
boolean isMobile = m.isMobile();
String moveDir = "/" + (!isGoMobile ? "order" : "mobile") + "/";
String tmpGroups = group.getUserGroup(uinfo);
int groupDisc = group.getMaxDiscRatio();

//목록
//orderItem.d(out);
DataSet list = orderItem.query(
	"SELECT a.*"
	+ ", c.id course_id, c.course_type, c.onoff_type, c.request_sdate, c.request_edate, c.credit, c.close_yn, c.sale_yn, c.disc_group_yn course_disc_group_yn "
	+ ", c.price c_price, b.book_price, b.delivery_type, b.delivery_price, b.disc_group_yn book_disc_group_yn "
	+ ", f.price freepass_price, f.disc_group_yn freepass_disc_group_yn "
	+ " FROM " + orderItem.table + " a "
	+ " LEFT JOIN " + course.table + " c ON a.product_type = 'course' AND a.product_id = c.id AND c.status = 1 "
	+ " LEFT JOIN " + book.table + " b ON a.product_type = 'book' AND a.product_id = b.id AND b.sale_yn = 'Y' AND b.status = 1 "
	+ " LEFT JOIN " + freepass.table + " f ON a.product_type = 'freepass' AND a.product_id = f.id AND f.status = 1 "
	+ " WHERE a.user_id = " + userId + " AND a.status = 10 "
	+ " ORDER BY a.course_id ASC, a.product_type DESC, a.id ASC "
);
while(list.next()) {
	list.put("course_block", false);
	list.put("book_block", false);
	list.put("freepass_block", false);
	list.put(list.s("product_type") + "_block", true);
	list.put("use_block", true);
	list.put("unit_price_conv", m.nf(list.i("unit_price")));
	list.put("price_conv", m.nf(list.i("price")));
	list.put("delivery_price_conv", m.nf(list.i("delivery_price")));
	list.put("delivery_block", list.i("delivery_price") > 0);
	list.put("product_type_conv", m.getItem(list.s("product_type"), orderItem.ptypes));
	list.put("credit", m.nf(list.i("credit")));

	orderItem.cancelDiscount(list.i("id"), list.i("coupon_user_id"));

	if("course".equals(list.s("product_type"))) {
		list.put("use_block", true);

		list.put("request_date", "");

		//삭제-그룹할인금액검사
		if(list.b("course_disc_group_yn") && 0 < groupDisc) {
			int discGroupPrice = list.i("price") * groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
			if(discGroupPrice != list.i("disc_group_price")) {
				orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
				isReload = true;
			}
		} else if(0 < list.i("disc_group_price")) {
			orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
			isReload = true;
		}

		if("R".equals(list.s("course_type"))) {
			list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));

			//삭제-기간이 지난 경우/금액틀림
			if(	0 > m.diffDate("D", list.s("request_sdate"), today)
				|| 0 > m.diffDate("D", today, list.s("request_edate"))
				|| list.b("close_yn")
				|| list.i("price") != list.i("c_price")
			) {
				orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
				isReload = true;
			}

		} else if("A".equals(list.s("course_type"))) {
			//list.put("request_date", "상시");

			//삭제-금액틀림
			if(list.i("price") != list.i("c_price") || list.b("close_yn")) {
				orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
				isReload = true;
			}
		}

		//삭제-판매마감
		if(!list.b("sale_yn")) {
			orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
			isReload = true;
		}

	} else if("book".equals(list.s("product_type"))) {
		//list.put("use_block", list.i("pay_price") == list.i("book_price"));
		list.put("use_block", true);

		//삭제-그룹할인금액검사
		if(list.b("book_disc_group_yn") && 0 < groupDisc) {
			int discGroupPrice = list.i("price") * groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
			if(discGroupPrice != list.i("disc_group_price")) {
				orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
				isReload = true;
			}
		} else if(0 < list.i("disc_group_price")) {
			orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
			isReload = true;
		}

		//삭제-금액틀림
		if(list.i("unit_price") != list.i("book_price")) {
			orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
			isReload = true;
		}
	} else if("freepass".equals(list.s("product_type"))) {
		//list.put("use_block", list.i("pay_price") == list.i("freepass_price"));
		list.put("use_block", true);

		//삭제-그룹할인금액검사
		if(list.b("freepass_disc_group_yn") && 0 < groupDisc) {
			int discGroupPrice = list.i("price") * groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
			if(discGroupPrice != list.i("disc_group_price")) {
				orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
				isReload = true;
			}
		} else if(0 < list.i("disc_group_price")) {
			orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
			isReload = true;
		}

		//삭제-금액틀림
		if(list.i("unit_price") != list.i("freepass_price")) {
			orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
			isReload = true;
		}
	}

}

//리로드
if(isReload) {
	m.jsAlert(_message.get("alert.order_item.canceled_by_change"));
	m.jsReplace("cart_list.jsp");
	return;
}


//폼입력
f.addElement("idx", null, "hname:'항목', required:'Y'");

//카트수정
if(m.isPost()) {

	if("qty".equals(f.get("mode"))) {
		//기본키
		int iid = f.getInt("order_item_id");
		if(0 == iid) { m.jsAlert(_message.get("alert.common.required_key")); return; }

		//정보
		DataSet info = orderItem.query(
			" SELECT a.*, b.book_price "
			+ " FROM " + orderItem.table + " a "
			+ " LEFT JOIN " + book.table + " b ON a.product_type = 'book' AND a.product_id = b.id AND b.status = 1 "
			//+ " WHERE a.id = " + iid + " AND a.user_id = " + userId + " AND a.order_id = -99 AND a.status = 10 "
			+ " WHERE a.id = " + iid + " AND a.user_id = " + userId + " AND a.status = 10 "
		);
		if(!info.next()) { m.jsAlert(_message.get("alert.common.nodata")); return; }

		//수정
		int qty = f.getInt("quantity");
		int unitPrice = info.i("book_price");
		if(qty < 1) qty = 1;
		if(qty > 1000) qty = 1000;
		orderItem.item("quantity", qty);
		orderItem.item("price", qty * unitPrice);
		orderItem.item("pay_price", qty * unitPrice);

		//그룹할인
		if(0 < info.i("disc_group_price") && 0 < groupDisc) {
			int discGroupPrice = qty * unitPrice * groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
			orderItem.item("disc_group_price", discGroupPrice);
			orderItem.item("pay_price", qty * (unitPrice - discGroupPrice));
		} else {
			orderItem.item("disc_group_price", 0);
			orderItem.item("pay_price", qty * unitPrice);
		}

		if(!orderItem.update("id = " + iid)) { m.jsAlert(_message.get("alert.common.error_modify")); return; }

		//이동
		m.jsReplace("cart_list.jsp?" + m.qs(), "parent");
		return;

	} else if(f.validate()) {
		String[] idx = m.reqArr("idx");

		//제한
		if(0 < orderItem.findCount("( status != 10 OR user_id != " + userId + " ) AND id IN (" + m.join(",", idx) + ")")) {
			m.jsError(_message.get("alert.order_item.permission_delete"));
			return;
		}

		//삭제
		int newOrderId = order.getSequence();
		orderItem.item("order_id", newOrderId);
		orderItem.item("status", 20);
		if(!orderItem.update("status = 10 AND user_id = " + userId + " AND id IN (" + m.join(",", idx) + ")")) {
			m.jsError(_message.get("alert.common.error_modify"));
			return;
		}

		//세션
		mSession.put("last_order_id", newOrderId);
		mSession.save();

		m.jsReplace("../order/payment.jsp?oek=" + order.getOrderEk(newOrderId, userId)/* + "&oid=" + m.encode(""+newOrderId)*/, "parent");
		return;
	}
}

//출력
p.setLayout(!isGoMobile ? ch : "mobile");
p.setBody("order.cart_list");
p.setVar("p_title", "장바구니");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);

p.setVar("move_dir", moveDir);
p.setVar("is_mobile", isMobile);
p.display();

%>