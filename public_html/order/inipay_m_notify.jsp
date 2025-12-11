<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//PG에서 보냈는지 IP로 체크 
String addr = userIp.toString();
if(!"118.129.210.25".equals(addr) && !"211.219.96.165".equals(addr) && !"183.109.71.153".equals(addr) && !"203.238.37.15".equals(addr)) {
	out.print("ERROR:미등록된서버요청");
	return;
}

String resultCode = m.rs("P_STATUS");
String resultMsg 	= m.rs("P_RMESG1");

int oid = m.ri("P_OID");
String mid = siteinfo.s("pg_id");					// 가맹점 ID 수신 받은 데이터로 설정
String tid= m.rs("P_TID");					// 취소 요청 tid에 따라서 유동적(가맹점 수정후 고정)
String paymethod = m.rs("P_TYPE");

if(oid == 0 || "".equals(tid)) {
	out.print("ERROR:결제정보오류");
	return;
}

m.log("inicis_noti", m.reqMap("").toString());

OrderDao order = new OrderDao(); order.setMessage(_message);
OrderItemDao orderItem = new OrderItemDao();
PaymentDao payment = new PaymentDao();

UserDao user = new UserDao();
MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

if("00".equals(resultCode)) {

	//가상계좌 채번시
	if("VBANK".equals(paymethod)) {
		out.print("OK");
		return;
	}

	DataSet info = order.find("id = " + oid + " AND status = -99");
	if(!info.next()) {
		out.print("ERROR:주문정보조회오류");
		return;
	}
						
	boolean bankAccount = false;
	int newPaymentId = payment.getSequence();

	payment.item("id", newPaymentId);
	payment.item("site_id", siteId);
	payment.item("pg_nm", "inicis");
	payment.item("reg_date", m.time("yyyyMMddHHmmss"));

	payment.item("oid", m.rs("P_OID")); //주문번호
	payment.item("mid", m.rs("P_MID"));
	payment.item("tid", m.rs("P_TID")); //거래번호
	payment.item("paytype", m.rs("P_TYPE")); //결제방법(지불수단)
	payment.item("respcode", m.rs("P_STATUS"));
	payment.item("respmsg", m.rs("P_RMESG1"));
	payment.item("amount", m.rs("P_AMT"));
	payment.item("buyer", m.rs("P_UNAME"));
	payment.item("buyeremail", m.rs("P_EMAIL"));
	payment.item("buyerphone", m.rs("P_MOBILE"));
	payment.item("productinfo", m.rs("P_GOODS"));

	String[] banks = {"03=>기업은행","04=>국민은행","05=>KEB하나(외한)은행","11=>농협중앙","20=>우리은행","23=>SC제일은행","26=>신한은행","27=>시티은행","31=>대구은행","32=>부산은행","34=>광주은행","37=>전북은행","38=>강원은행","39=>경남은행","40=>충북은행","45=>새마을금고","53=>씨티은행","71=>우체국","81=>KEB하나은행"};

	payment.item("paydate", m.rs("P_AUTH_DT")); //승인날짜
	payment.item("timestamp", m.rs("P_AUTH_DT")); //승인시간
	payment.item("accountnum", m.rs("P_VACT_NUM")); //입금계좌번호
	payment.item("financecode", m.rs("P_VACT_BANK_CODE")); //은행코드			
	payment.item("financename", m.getItem(m.rs("P_VACT_BANK_CODE"), banks)); //은행명
	payment.item("accountowner", m.rs("P_VACT_NAME")); //예금주
	payment.item("saowner", m.rs("P_VACT_NAME")); //예금주
	payment.item("payer", m.rs("P_UNAME")); //송금자명

	payment.item("cashreceiptcode", m.rs("P_CSHR_CODE")); //현금영수증 발급결과
	payment.item("cashreceiptkind", m.rs("P_CSHR_TYPE")); //현금영수증 발급구분코드 (0-소득공제용, 1-지출증빙용)

	payment.item("telno", m.rs("P_HPP_NUM")); //휴대폰번호

	payment.item("cardnum", m.rs("P_CARD_NUM")); //카드번호					
	payment.item("financeauthnum", m.rs("P_AUTH_NO")); //승인번호
	payment.item("cardnointyn", m.rs("P_CARD_INTEREST")); //할부요형

	if(!payment.insert()) {
		out.print("ERROR:결제정보입력오류");
		return;
	}

	order.item("pay_date", m.time());
	order.item("status", 1);
	if(!order.update("id = " + oid + " AND status = -99")) {
		out.print("ERROR:주문정보수정오류");
		return;
	}
	
	//주문처리
	order.process(oid);

	//발송
	DataSet uinfo = user.find("id = " + info.s("user_id"));
	info.put("pay_price_conv", m.nf(info.i("pay_price")));
	info.put("order_date_conv", m.time(_message.get("format.date.local"), info.s("order_date")));
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

	out.print("OK");

} else if("02".equals(resultCode)) {
	if(order.findCount("id = " + oid + " AND status = 2") > 0) {
		order.confirmDeposit("" + oid, siteinfo);
	}
	out.print("OK");
} else {
	out.print("ERROR:실패");
}

%>