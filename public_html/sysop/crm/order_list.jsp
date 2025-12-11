<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
OrderDao order = new OrderDao();
PaymentDao payment = new PaymentDao();

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(f.get("mode")) ? 20000 : 15);
lm.setTable(
	order.table + " a "
	+ " LEFT JOIN " + payment.table + " p ON p.oid = a.id AND p.respcode = '0000' "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " AND u.status != -1 "
);
lm.setFields("a.*, p.id payment_id, u.login_id, u.user_nm");
lm.addWhere("a.user_id = " + uid + "");
lm.addWhere("a.status > -1");
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
	list.put("payment_block", list.i("payment_id") > 0);

	list.put("pay_date_conv", m.time("yyyy.MM.dd", list.s("pay_date")));
	list.put("refund_date_conv", m.time("yyyy.MM.dd", list.s("refund_date")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("ord_mobile", !"".equals(list.s("ord_mobile")) ? list.s("ord_mobile") : "-" );
	list.put("ord_phone", !"".equals(list.s("ord_phone")) ? list.s("ord_phone") : "-" );

}

//출력
p.setLayout(ch);
p.setBody("crm.order_list");
p.setVar("p_title", "주문목록");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("tab_order", "current");

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.display();

%>