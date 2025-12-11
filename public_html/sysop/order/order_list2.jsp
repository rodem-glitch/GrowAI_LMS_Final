<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.07.14

//접근권한
if(!Menu.accessible(60, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
OrderDao order = new OrderDao();
PaymentDao payment = new PaymentDao();
UserDao user = new UserDao();

//폼체크
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);
f.addElement("s_method", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(f.get("mode")) ? 20000 : 20);
lm.setTable(
	order.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " "
);
lm.setFields("a.*, u.login_id, u.user_nm");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.order_date", m.time("yyyyMMdd", f.get("s_sdate")), ">=");
lm.addSearch("a.order_date", m.time("yyyyMMdd", f.get("s_edate")), "<=");
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.paymethod", f.get("s_method"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.id, a.order_nm, a.ord_nm, u.login_id", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(f.get("ord")) ? f.get("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("method_conv", m.getItem(list.s("paymethod"), order.methods));
	list.put("order_date_conv", m.time("yyyy.MM.dd", list.s("order_date")));
	list.put("pay_price_conv", m.nf(list.i("pay_price")));
	list.put("status_conv", m.getItem(list.s("status"), order.statusList));
	list.put("payment_block", list.i("status") > 0);

	list.put("pay_date_conv", m.time("yyyy.MM.dd", list.s("pay_date")));
	list.put("refund_date_conv", m.time("yyyy.MM.dd", list.s("refund_date")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));

}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "주문관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>주문아이디", "order_date_conv=>주문일", "user_nm=>회원명", "login_id=>회원아이디", "order_nm=>주문명", "price=>주문총액", "pay_price=>실결제금액", "method_conv=>결제방법", "pay_date_conv=>실결제일", "refund_price=>환불금액(총계)", "refund_date_conv=>환불일(최종)", "refund_note=>환불비고(최종)", "ord_nm=>주문자명", "ord_reci=>수령자명", "ord_zipcode=>배송지우편번호", "ord_address=>구배송지주소", "ord_new_address=>도로주소", "ord_addr_dtl=>상세주소", "ord_email=>주문자이메일", "ord_phone=>주문자연락처", "ord_mobile=>주문자휴대폰", "ord_memo=>주문자요청사항", "reg_date_conv=>등록일", "status_conv=>상태" }, "주문관리(" + m.time("yyyy-MM-dd") + ")");
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

p.setLoop("methods", m.arr2loop(order.methods));
p.setLoop("status_list", m.arr2loop(order.statusList));
p.display();

%>