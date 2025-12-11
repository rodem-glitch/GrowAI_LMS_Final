<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
double payamt = !"".equals(m.rs("payamt")) ? Double.parseDouble(m.rs("payamt")) : 0.0;
int payPrice = (int)payamt;
int oid = m.ri("storeorderno");
String retcode = m.rs("retcode");
String retmsg = m.rs("retmsg");
String pginfo = m.rs("pginfo");
String cmid = m.rs("storeid");
String custom = m.rs("custom");
String[] customArr = m.split("-", custom);

//객체
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao(siteId);
PaymentDao payment = new PaymentDao();

CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

//변수
boolean isDBOK = true;
int newPaymentId = 0;
String payUrl = "/mypage/payment.jsp?oek=" + order.getOrderEk(oid, userId);

//제한
if(!"0".equals(retcode) || (!"OK".equals(retmsg) && !"SUCCESS".equals(retmsg))) { m.jsAlert(_message.get("alert.payment.error") + "\\n\\nERROR CODE : " + retcode + "\\nERROR MESSAGE : " + retmsg); m.jsReplace(payUrl); return; }

//제한-커스텀해시
if(2 != customArr.length) { m.jsError(_message.get("alert.order.abnormal")); return; }
if(!customArr[1].equals(m.encrypt("LMS_PAYPAL_" + siteId + "_" + oid + "_" + customArr[0] + "_" + payPrice + userId))) { m.jsError(_message.get("alert.order.abnormal")); return; }

//정보-주문
DataSet info = order.find("id = ? AND user_id = ? AND site_id = ? AND status = -99", new Integer[] {oid, userId, siteId});
if(!info.next()) { m.jsAlert(_message.get("alert.order.nodata")); m.jsReplace(payUrl); return; }

//처리-주문
newPaymentId = payment.getSequence();

payment.item("id", newPaymentId);
payment.item("site_id", siteId);
payment.item("pg_nm", "payletter");
payment.item("reg_date", m.time("yyyyMMddHHmmss"));

payment.item("oid", oid); //주문번호
payment.item("mid", cmid);
payment.item("tid", "pl" + oid + customArr[0]); //거래번호
payment.item("paytype", "10"); //결제방법(지불수단)
payment.item("respcode", retcode);
payment.item("respmsg", retmsg);
payment.item("amount", payPrice);
payment.item("buyer", uinfo.s("user_nm"));
payment.item("buyeremail", uinfo.s("email"));
payment.item("productinfo", info.s("order_nm"));

payment.item("paydate", sysNow); //승인날짜
payment.item("financename", pginfo); //은행명

payment.item("reg_date", sysNow); //은행명

if(!payment.insert()) isDBOK = false;

if(isDBOK) {
	order.item("pay_date", sysNow);
	order.item("status", 2);
	if(!order.update("id = " + oid + " AND status = -99")) isDBOK = false;
}

//갱신-주문항목
if(isDBOK) {
	orderItem.item("order_id", oid);
	orderItem.item("status", 2);
	if(!orderItem.update("id IN (" + info.s("items") + ")")) isDBOK = false;		
}

if(isDBOK == false) {
	m.jsAlert(_message.get("alert.order.error_wrapup"));
	m.jsReplace(payUrl);
	return;
}

//주문처리
order.process(oid);

//발송
info.put("pay_price_conv", m.nf(info.i("pay_price")));
info.put("order_date_conv", m.time(_message.get("format.date.dot"), info.s("order_date")));
info.put("paymethod_conv", m.getItem(info.s("paymethod"), order.methods));

DataSet items = orderItem.find("id IN (" + info.s("items") + ")");
while(items.next()) {
	items.put("quantity_conv", m.nf(items.i("quantity")));
	items.put("pay_price_conv", m.nf(items.i("pay_price")));
}

p.setVar("order", info);
p.setLoop("order_items", items);
mail.send(siteinfo, uinfo, "payment", p);
smsTemplate.sendSms(siteinfo, uinfo, "payment", p, "P");

//정상처리시 결과페이지로
String eKey = m.encrypt(oid + userId + "__LMS2014");
m.jsReplace("payment_complete.jsp?ek=" + eKey + "&oid=" + m.encode(""+oid), "parent");
return;

%>