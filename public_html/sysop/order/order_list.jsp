<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(60, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
PaymentDao payment = new PaymentDao();
UserDao user = new UserDao(isBlindUser);

//입금확인
if("deposit".equals(m.rs("mode"))) {
	//기본키
	String oid = m.rs("oid");
	if("".equals(oid)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	if(!order.confirmDeposit(oid, siteinfo)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("입금확인이 완료됐습니다.");
	m.jsReplace("order_list.jsp?" + m.qs("mode,oid"), "parent");
	return;
}

//수정중
//삭제
if("del".equals(m.rs("mode"))) {

	int id = m.ri("id");
	if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	order.item("status", -1);
	if(!order.update("id = " + id + " AND site_id = " + siteId + "")) {
		m.jsAlert("삭제하는 중 오류가 발생했습니다."); return;
	}

	m.jsAlert("삭제되었습니다.");
	m.jsReplace("order_list.jsp?" + m.qs("mode,id"), "parent");
	return;
}

//폼체크
f.addElement("s_order_sdate", null, null);
f.addElement("s_order_edate", null, null);
f.addElement("s_pay_sdate", null, null);
f.addElement("s_pay_edate", null, null);
f.addElement("s_method", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(f.get("mode")) ? 20000 : 20);
lm.setTable(
	order.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " "
);
lm.setFields(
	"a.*, u.login_id, u.user_nm, u.email_yn, u.sms_yn, u.status user_status"
	+ ", (SELECT SUM(quantity) FROM " + orderItem.table + " WHERE order_id = a.id AND status != -1) item_quantity "
	+ ", (SELECT COUNT(*) FROM " + orderItem.table + " WHERE order_id = a.id AND status != -1) item_count "
);
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.order_date", m.time("yyyyMMdd", f.get("s_order_sdate")), ">=");
lm.addSearch("a.order_date", m.time("yyyyMMdd", f.get("s_order_edate")), "<=");
lm.addSearch("a.pay_date", m.time("yyyyMMdd000000", f.get("s_pay_sdate")), ">=");
lm.addSearch("a.pay_date", m.time("yyyyMMdd235959", f.get("s_pay_edate")), "<=");
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.paymethod", f.get("s_method"));
if(f.getInt("s_status") != -99) lm.addWhere("a.status != -99");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.id, a.order_nm, a.ord_nm, u.login_id", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(f.get("ord")) ? f.get("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("user_out_block", -1 == list.i("user_status"));
	list.put("login_id_conv", !list.b("user_out_block") ? list.s("login_id") : "[탈퇴]");
	list.put("email_yn_conv", m.getItem(list.s("email_yn"), user.receiveYn));
	list.put("sms_yn_conv", m.getItem(list.s("sms_yn"), user.receiveYn));

	list.put("method_conv", m.getItem(list.s("paymethod"), order.methods));
	list.put("order_date_conv", m.time("yyyy.MM.dd", list.s("order_date")));
	list.put("pay_price_conv", m.nf(list.i("pay_price")));
	list.put("status_conv", m.getItem(list.s("status"), order.statusList));
	list.put("payment_block", !"99".equals(list.s("paymethod")));

	list.put("pay_date_conv", !"".equals(list.s("pay_date")) ? m.time("yyyy.MM.dd", list.s("pay_date")) : "-");
	list.put("refund_date_conv", m.time("yyyy.MM.dd", list.s("refund_date")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));

	list.put("deposit_block", "90".equals(list.s("paymethod")) && 2 == list.i("status"));
	list.put("important_block", list.b("deposit_block"));
	list.put("ROW_CLASS", list.b("important_block") ? "important" : list.s("ROW_CLASS"));
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "주문관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>주문아이디", "order_date_conv=>주문일", "user_nm=>회원명", "login_id_conv=>회원아이디", "order_nm=>주문명", "item_count=>주문항목수", "item_quantity=>전체주문수량", "price=>주문총액", "coupon_price=>쿠폰할인금액", "disc_group_price=>회원할인금액", "pay_price=>실결제금액", "method_conv=>결제방법", "pay_date_conv=>실결제일", "refund_price=>환불금액(총계)", "refund_date_conv=>환불일(최종)", "refund_note=>환불비고(최종)", "ord_nm=>주문자명", "ord_reci=>수령자명", "ord_zipcode=>배송지우편번호", "ord_address=>구배송지주소", "ord_new_address=>도로주소", "ord_addr_dtl=>상세주소", "ord_email=>주문자이메일", "ord_phone=>주문자연락처", "ord_mobile=>주문자휴대폰", "ord_memo=>주문자요청사항", "email_yn_conv=>이메일수신동의여부", "sms_yn_conv=>SMS수신동의여부", "reg_date_conv=>등록일", "status_conv=>상태" }, "주문관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("order.order_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setVar("isMalgn", isMalgnOffice && "malgn".equals(loginId)); //수정중

//p.setLoop("methods", m.arr2loop(order.methods));
p.setLoop("methods", payment.getMethods(siteinfo));
p.setLoop("status_list", m.arr2loop(order.statusList));
p.display();

%>