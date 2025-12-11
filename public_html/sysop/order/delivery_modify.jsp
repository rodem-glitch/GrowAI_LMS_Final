<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(111, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

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
DeliveryDao delivery = new DeliveryDao();
BookDao book = new BookDao();

//정보
DataSet info = order.query(
	"SELECT a.*, u.login_id, u.user_nm, d.link "
	+ " FROM " + order.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " LEFT JOIN " + delivery.table + " d ON a.delivery_id = d.id "
	+ " WHERE a.id = " + id + " AND a.status != -1"
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("wait_block", info.i("status") == 1 && (info.i("delivery_status") == 0 || info.i("delivery_status") == 2));
info.put("order_date_conv", m.time("yyyy.MM.dd", info.s("order_date")));
info.put("pay_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("pay_date")));
info.put("pay_date_diff", (!"".equals(info.s("pay_date")) ? m.diffDate("D", info.s("pay_date"), m.time("yyyyMMddHHmmss")) : "-"));
info.put("status_conv", m.getItem(info.s("status"), order.statusList));
info.put("done_block", info.i("status") < 0 || info.i("delivery_status") == 1);
info.put("price_conv", m.nf(info.i("price")));
info.put("coupon_price_conv", m.nf(info.i("coupon_price")));
info.put("pay_price_conv", m.nf(info.i("pay_price")));
info.put("delivery_price_conv", m.nf(info.i("delivery_price")));
info.put("paymethod_conv", m.getItem(info.s("paymethod"), order.methods));
String mobile = "";
if(!"".equals(info.s("ord_mobile"))) mobile = SimpleAES.decrypt(info.s("ord_mobile"));
info.put("ord_mobile", mobile);
info.put("delivery_type_conv", m.getItem(info.s("delivery_type"), order.deliveryTypeList));
info.put("delivery_block", !"N".equals(info.s("delivery_type")));
user.maskInfo(info);

//기록-개인정보조회
if(info.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, info.size(), "이러닝 운영", info);

//폼체크
f.addElement("delivery_status", info.s("delivery_status"), "hname:'배송상태', required:'Y'");
f.addElement("delivery_id", info.s("delivery_id"), "hname:'택배사', required:'Y'");
f.addElement("delivery_no", info.s("delivery_no"), "hname:'운송장번호'");

//수정
if(m.isPost() && f.validate()) {
	//제한
	if(info.b("done_block")) { m.jsAlert("결제취소 또는 구매확정 된 주문은 수정할 수 없습니다."); return; }

	//UPLUS에스크로배송정보등록
	String deliveryCd = delivery.getOne("SELECT delivery_cd FROM " + delivery.table + " WHERE id = " + f.get("delivery_id"));

	boolean isDev = ("lgdacomxpay".equals(siteinfo.s("pg_id")) || -1 < request.getServerName().indexOf("lms.malgn.co.kr"));
	if(info.b("escrow_yn") && "".equals(info.s("delivery_no")) && !order.setUplusDeliveryInfo(siteinfo, info, deliveryCd, f.get("delivery_no"), isDev)) {
		m.jsAlert("에스크로 배송정보를 등록하는 중 오류가 발생했습니다.");
		return;
	}

	//수정
	order.item("delivery_status", f.get("delivery_status"));
	order.item("delivery_id", f.get("delivery_id"));
	order.item("delivery_no", f.get("delivery_no"));

	if(!order.update("id = " + id)) { m.jsAlert("배송정보를 수정하는 중 오류가 발생했습니다."); return; }

	//이동
	if("poplayer".equals(ch)) m.jsReplace("delivery_modify.jsp?" + m.qs(), "parent");
	else m.jsReplace("delivery_list.jsp?" + m.qs("id"), "parent");
	return;
}

//정보-결제
DataSet plist = payment.find("oid = " + id + "");
if(0 < plist.size()) info.put("payment_block", true);

//목록
DataSet list = orderItem.query(
	"SELECT a.id, a.quantity, b.* "
	+ " FROM " + orderItem.table + " a "
	+ " LEFT JOIN " + book.table + " b ON a.product_id = b.id "
	+ " WHERE a.order_id = '" + id + "' AND a.product_type = 'book' AND a.status != -1 "
	+ " ORDER BY a.id ASC "
);
while(list.next()) {
	if(!"".equals(list.s("book_img"))) list.put("book_img_url", m.getUploadUrl(list.s("book_img")));
	list.put("quantity_conv", m.nf(list.i("quantity")));
}

//출력
p.setLayout(ch);
p.setBody("order.delivery_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("list", list);
p.setVar("modify", true);

p.setLoop("delivery_list", delivery.find("status = 1"));
p.setLoop("delivery_status_list", m.arr2loop(order.deliveryStatusList));
p.display();

%>