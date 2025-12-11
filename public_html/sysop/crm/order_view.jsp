<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
CourseDao course = new CourseDao();
PaymentDao payment = new PaymentDao();
CourseUserDao courseUser = new CourseUserDao();
RefundDao refund = new RefundDao();

//정보
DataSet info = order.query(
	"SELECT a.*, u.login_id, u.user_nm "
	+ " FROM " + order.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1 "
	+ " WHERE a.id = " + id + " AND a.status != -1"
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("order_date_conv", m.time("yyyy.MM.dd", info.s("order_date")));
info.put("pay_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("pay_date")));
info.put("price_conv", m.nf(info.i("price")));
info.put("disc_price_conv", m.nf(info.i("disc_price")));
info.put("coupon_price_conv", m.nf(info.i("coupon_price")));
info.put("pay_price_conv", m.nf(info.i("pay_price")));
info.put("refund_price_conv", m.nf(info.i("refund_price")));
info.put("delivery_price_conv", m.nf(info.i("delivery_price")));
info.put("refund_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("refund_date")));
info.put("paymethod_conv", m.getItem(info.s("paymethod"), order.methods));
info.put("status_conv", m.getItem(info.s("status"), order.statusList));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
info.put("delete_block", info.i("status") == 2 && "SC0040".equals(info.s("paymethod")));
String mobile = "";
if(!"".equals(info.s("ord_mobile"))) mobile = info.s("ord_mobile");
info.put("ord_mobile", mobile);
info.put("delivery_type_conv", m.getItem(info.s("delivery_type"), order.deliveryTypeList));
info.put("delivery_block", !"N".equals(info.s("delivery_type")));

//처리
if("del".equals(m.rs("mode"))) {
	//제한-입금대기/무통장입금
	if(!(info.i("status") == 2 && "03".equals(info.s("paymethod")))) {
		m.jsAlert(
			"주문삭제를 할 수 없는 주문내역입니다. "
			+ "\n( 무통장입금으로 신청하고 입금대기인 경우에만 취소할 수 있습니다. )"
		);
		return;
	}

	if(-1 == order.execute("DELETE FROM " + order.table + " WHERE id = " + id + "")) { }
	if(-1 == orderItem.execute("DELETE FROM " + orderItem.table + " WHERE order_id = " + id + "")) { }
	if(-1 == courseUser.execute("DELETE FROM " + courseUser.table + " WHERE order_id = " + id + "")) { }

	m.jsAlert("주문삭제 되었습니다.");
	m.jsReplace("order_list.jsp" + m.qs("id, mode"));
	return;
}

//환불신청
if("refund".equals(m.rs("mode"))) {
	//기본키
	int iid = m.ri("iid");
	if(iid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	//정보-주문항목
	DataSet oiinfo = orderItem.find("id = " + iid + " AND order_id = " + id + " AND status = 1");
	if(!oiinfo.next()) { m.jsAlert("해당 결제정보가 없습니다."); return; }

	//정보-환불
	DataSet rinfo = refund.find("order_id = " + id + " AND order_item_id = " + iid + "");
	if(rinfo.next()) { m.jsAlert("해당 주문항목은 이미 환불처리가 되었습니다."); return; }

	//환불 등록
	refund.item("site_id", siteId);
	refund.item("user_id", oiinfo.i("user_id"));
	refund.item("course_id", oiinfo.i("course_id"));
	refund.item("order_id", id);
	refund.item("order_item_id", iid);
	refund.item("refund_type", 3);
	refund.item("req_memo", "");
	refund.item("paymethod", info.s("paymethod"));
	refund.item("reg_date", m.time("yyyyMMddHHmmss"));
	refund.item("status", 1);
	if(!refund.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//아이템상태변경
	orderItem.item("status", 3);
	if(!orderItem.update("id = " + iid + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("order_view.jsp?" + m.qs("iid, mode"), "parent");
	return;
}

//정보-결제
DataSet pinfo = payment.find("oid = " + id + "");
if(pinfo.next()) {
	info.put("payment_id", pinfo.s("id"));
	info.put("payment_block", true);
}

//목록
DataSet list = orderItem.query(
	"SELECT a.* "
	+ ", r.id rid, r.status r_status "
	+ " FROM " + orderItem.table + " a "
	+ " LEFT JOIN " + refund.table + " r ON r.order_id = a.order_id AND r.order_item_id = a.id "
	+ " WHERE a.order_id = '" + id + "' AND a.status != -1 "
	+ " ORDER BY a.id ASC "
);
while(list.next()) {
	if("book".equals(list.s("product_type"))) { info.put("book_block", true); }

	list.put("price_conv", m.nf(list.i("price")));
	list.put("disc_price_conv", m.nf(list.i("disc_price")));
	list.put("coupon_price_conv", m.nf(list.i("coupon_price")));
	list.put("pay_price_conv", m.nf(list.i("pay_price")));
	list.put("refund_price_conv", m.nf(list.i("refund_price")));
	list.put("product_type_conv", m.getItem(list.s("product_type"), orderItem.ptypes));
	list.put("refund_block", list.i("rid") == 0 && list.i("pay_price") > 0);
	list.put("status_conv", m.getItem(list.s("r_status"), refund.statusList));
}

//출력
p.setLayout(ch);
p.setBody("crm.order_view");
p.setVar("p_title", "주문정보");
p.setVar("list_query", m.qs("id,mode"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("tab_order", "current");

p.setVar(info);
p.setLoop("list", list);

p.display();

%>