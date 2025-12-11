<%@ page contentType="text/html; charset=utf-8" %><%@ page import="lgdacom.XPayClient.XPayClient"%><%@ include file="my_init.jsp" %><%

//기본키
int oid = m.parseInt(m.decode(m.rs("oid")));
String ek = m.rs("ek");
if(0 == oid || "".equals(ek)) { m.jsError(_message.get("alert.common.required_key")); return; }

//암호키
String eKey = m.encrypt(oid + userId + "__LMS2014");
if(!eKey.equals(ek)) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//객체
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
PaymentDao payment = new PaymentDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//주문정보
DataSet info = order.find("id = " + oid + " AND user_id = " + userId + " AND site_id = " + siteId + "");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
info.put(info.s("paymethod") + "_block", true);
info.put("paymethod_conv", m.getItem(info.s("paymethod"), order.methods));
info.put("pay_price_conv", m.nf(info.i("pay_price")));

//주문내역
int totalQuantity = 0;
DataSet oilist = orderItem.find("order_id = ? AND user_id = ? AND site_id = ?", new Integer[] { oid, userId, siteId });
while(oilist.next()) {
	totalQuantity = totalQuantity + oilist.i("quantity");
	oilist.put("quantity_conv", m.nf(oilist.i("quantity")));
	oilist.put("unit_price_conv", m.nf(oilist.i("unit_price")));
	oilist.put("pay_price_conv", m.nf(oilist.i("pay_price")));
}
info.put("total_quantity", totalQuantity);

//수강생목록
DataSet culist = courseUser.query(
	" SELECT a.*, c.course_nm "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " WHERE a.order_id = ? AND a.user_id = ? AND a.site_id = ? AND a.status IN (1, 3) "
	, new Integer[] { oid, userId, siteId }
);
info.put("course_user_block", 0 < culist.size());

//결제정보
DataSet pinfo = new DataSet();
if(!"99".equals(info.s("paymethod")) && !"90".equals(info.s("paymethod"))) {
	pinfo = payment.find("oid = " + oid + " AND site_id = " + siteId + "", "*", "id DESC", 1);
	if(!pinfo.next()) { m.jsAlert(_message.get("alert.common.nodata")); return; }
	pinfo.put("financename", pinfo.s("financename").replace("은행", ""));
	pinfo.put("paydate_conv", m.time(_message.get("format.datetime.dot"), pinfo.s("paydate")));
	pinfo.put("cardinstallmonth_conv", pinfo.i("cardinstallmonth") == 0 ? "일시불" : pinfo.i("cardinstallmonth") + "개월");
}

//출력
p.setLayout(ch);
p.setBody("mobile.payment_complete");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("payment", pinfo);
p.setLoop("courseuser_list", culist);
p.setLoop("orderitem_list", oilist);

p.display();

%>