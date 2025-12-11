<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

/*
** ORDER 상태 -- "1=>완료", "2=>입금대기", "-2=>결제취소", "3=>부분환불", "4=>전액환불"
** ORDER paymethod --  "SC0010=>신용카드", "SC0030=>계좌이체", "SC0040=>무통장입금"
** ORDER_ITEM 상태 -- "1=>완료", "2=>입금대기", "3=>환불요청", "-2=>결제취소
** REFUND 상태 -- "1=>처리중", "2=>완료", "-1=>환불불가"
** REFUND refund_type -- "1=>부분환불", "2=>전액환불"
** REFUND paymethod -- "1=>계좌이체", "2=>카드취소"
*/


//접근권한
if(!Menu.accessible(60, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

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
UserDao user = new UserDao(isBlindUser);

//정보
DataSet info = order.query(
	"SELECT a.*, u.login_id, u.user_nm, u.status user_status "
	+ " FROM " + order.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1"
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("ord_memo_conv", m.nl2br(info.s("ord_memo")));
info.put("order_date_conv", m.time("yyyy.MM.dd", info.s("order_date")));
info.put("pay_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("pay_date")));
info.put("price_conv", m.nf(info.i("price")));
info.put("disc_price_conv", m.nf(info.i("disc_price")));
info.put("disc_group_price_conv", m.nf(info.i("disc_group_price")));
info.put("coupon_price_conv", m.nf(info.i("coupon_price")));
info.put("pay_price_conv", m.nf(info.i("pay_price")));
info.put("refund_price_conv", m.nf(info.i("refund_price")));
info.put("delivery_price_conv", m.nf(info.i("delivery_price")));
info.put(info.s("paymethod") + "_block", true);
info.put("refund_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("refund_date")));
info.put("paymethod_conv", m.getItem(info.s("paymethod"), order.methods));
info.put("status_conv", m.getItem(info.s("status"), order.statusList));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
info.put("delete_block", info.i("status") == 2 && ("03".equals(info.s("paymethod")) || "90".equals(info.s("paymethod"))));
info.put("order_waiting_block", -99 == info.i("status"));
String mobile = "";
if(!"".equals(info.s("ord_mobile"))) mobile = SimpleAES.decrypt(info.s("ord_mobile"));
info.put("ord_mobile", mobile);
info.put("delivery_type_conv", m.getItem(info.s("delivery_type"), order.deliveryTypeList));
info.put("delivery_block", !"N".equals(info.s("delivery_type")));
info.put("deposit_block", "90".equals(info.s("paymethod")) && 2 == info.i("status"));
info.put("force_deposit_block", !"90".equals(info.s("paymethod")) && 2 == info.i("status"));
info.put("user_out_block", -1 == info.i("user_status"));
user.maskInfo(info);

//기록-개인정보조회
if("".equals(m.rs("mode")) && info.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, info.size(), "이러닝 운영", info);

//처리
if("del".equals(m.rs("mode"))) {
	//제한-입금대기/무통장입금
	if(!(2 == info.i("status") && ("03".equals(info.s("paymethod")) || "90".equals(info.s("paymethod"))))) {
		m.jsAlert("취소할 수 없는 주문입니다.\n(무통장입금으로 신청하고 입금대기인 경우에만 취소할 수 있습니다.)");
		return;
	}

	order.item("status", -2);
	order.item("ord_memo", info.s("ord_memo") + "<br>[" + m.time("yyyy.MM.dd HH:mm") + "] 관리자에 의한 무통장입금 취소");
	order.update("id = " + id);

	orderItem.item("status", -2);
	orderItem.update("order_id = " + id);

	courseUser.item("change_date", m.time("yyyyMMddHHmmss"));
	courseUser.item("status", -4);
	courseUser.update("order_id = " + id);

	//if(-1 == order.execute("DELETE FROM " + order.table + " WHERE id = " + id + "")) { }
	//if(-1 == orderItem.execute("DELETE FROM " + orderItem.table + " WHERE order_id = " + id + "")) { }
	//if(-1 == courseUser.execute("DELETE FROM " + courseUser.table + " WHERE order_id = " + id + "")) { }

	m.jsAlert("무통장입금이 취소되었습니다.");
	m.jsReplace("order_view.jsp?" + m.qs("mode"), "parent");
	return;

} else if("deposit".equals(m.rs("mode"))) {
	//입금확인
	if(!order.confirmDeposit(Integer.toString(id), siteinfo)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("입금확인이 완료됐습니다.");
	m.jsReplace("order_view.jsp?" + m.qs("mode"), "parent");
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
	DataSet rinfo = refund.find("order_id = " + id + " AND order_item_id = " + iid + " AND status != -2"); //수정중
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

//주문대기삭제
if("order_cancel".equals(m.rs("mode"))) {
	//제한
	if(-99 < info.i("status")) {
		m.jsAlert("취소할 수 없는 주문입니다.");
		return;
	}
	
	//주문상태변경
	order.item("status", -1);
	if(!order.update("id = " + id + " AND status = -99")) { m.jsAlert("주문을 수정하는 중 오류가 발생했습니다."); return; }

	//쿠폰취소
	DataSet oilist = orderItem.find("order_id = " + id + " AND status = -99");
	while(oilist.next()) {
		if(!orderItem.cancelDiscount(oilist.i("id"), oilist.i("coupon_user_id"))) { m.jsAlert("적용된 쿠폰을 해제하는 중 오류가 발생했습니다."); return; }
	}

	//아이템상태변경
	orderItem.item("status", -1);
	if(!orderItem.update("order_id = " + id + " AND status = -99")) { m.jsAlert("주문항목을 수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("order_list.jsp?" + m.qs("id, mode"), "parent");
	return;
}

//목록-결제
DataSet plist = payment.find("oid = " + id + "");
if(0 < plist.size()) info.put("payment_block", true);

//정보-승인결제
DataSet pinfo = new DataSet();
if(-99 == info.i("status") || "90".equals(info.s("paymethod")) || "99".equals(info.s("paymethod"))) {
	p.setVar("pg_block", false);
	p.setVar("receipt_block", false);
} else {
	p.setVar("pg_block", true);
	p.setVar(
		"receipt_block"
		, (
			"01".equals(info.s("paymethod")) && (1 == info.i("status") || 3 == info.i("status") || 4 == info.i("status"))
			|| ("02".equals(info.s("paymethod")) || "03".equals(info.s("paymethod"))) && 1 == info.i("status")
		)
	);

	pinfo = payment.find("oid = " + id + " AND respcode IN ('0000', '0001', '00')");
	if(!pinfo.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
	pinfo.put("paydate_conv", m.time(_message.get("format.datetime.dot"), pinfo.s("paydate")));
	pinfo.put("cardinstallmonth_conv", pinfo.i("cardinstallmonth") == 0 ? _message.get("payment.unit.month_single") : pinfo.i("cardinstallmonth") + _message.get("payment.unit.month_multi"));
	pinfo.put("amount_conv", m.nf(pinfo.i("amount")));

	//authdata는 LGU+에서만 사용됨. LGU+에서 올앳으로 변경한 경우 pg_key가 변경되어 오류 발생. lgu_pg_key 추가함. by hopegiver [2019-06-05]
	String pgKey = "lgu".equals(siteinfo.s("pg_nm")) ? siteinfo.s("pg_key") : SiteConfig.s("lgu_pg_key");
	pinfo.put("authdata", m.encrypt(pinfo.s("mid") + pinfo.s("tid") + pgKey));
	pinfo.put("caslimitdate_conv", (8 != pinfo.s("caslimitdate").length() ? "-" : m.time("yyyy.MM.dd", pinfo.s("caslimitdate"))));
}

//목록
DataSet list = orderItem.query(
	"SELECT a.* "
	+ ", r.id rid, r.status r_status "
	+ " FROM " + orderItem.table + " a "
	+ " LEFT JOIN " + refund.table + " r ON r.order_id = a.order_id AND r.order_item_id = a.id AND r.status != -2" //수정중
	+ " WHERE a.order_id = '" + id + "' AND a.status != -1 "
	+ " ORDER BY a.id ASC "
);
while(list.next()) {
	if("book".equals(list.s("product_type"))) { info.put("book_block", true); }

	list.put("product_nm_conv", m.cutString(list.s("product_nm"), 90));
	list.put("quantity_conv", m.nf(list.i("quantity")));
	list.put("unit_price_conv", m.nf(list.i("unit_price")));
	list.put("price_conv", m.nf(list.i("price")));
	list.put("disc_price_conv", m.nf(list.i("disc_price")));
	list.put("disc_group_price_conv", m.nf(list.i("disc_group_price")));
	list.put("coupon_price_conv", m.nf(list.i("coupon_price")));
	list.put("pay_price_conv", m.nf(list.i("pay_price")));
	list.put("refund_price_conv", m.nf(list.i("refund_price")));
	list.put("product_type_conv", m.getItem(list.s("product_type"), orderItem.ptypes));
	list.put("refund_block", (list.i("rid") == 0 || list.i("r_status") == -2 ) && list.i("pay_price") > 0 && -2 != list.i("status"));//수정중
	list.put("status_conv", m.getItem(list.s("r_status"), refund.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "주문내역_" + id + "(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>아이디", "product_type_conv=>타입", "quantity=>수량", "product_nm=>과정명/상품명", "price=>판매인가", "coupon_price=>쿠폰할인", "disc_group_price=>회원그룹할인", "pay_price=>실결제금액", "refund_price=>환불액" }, "주문내역_" + id + "(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setLayout(ch);
p.setBody("order.order_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("payment", pinfo);
p.setLoop("list", list);

p.display();

%>