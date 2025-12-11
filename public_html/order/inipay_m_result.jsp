<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%
	
String resultCode = m.rs("P_STATUS");
String resultMsg 	= m.rs("P_RMESG1");

int oid = m.ri("P_NOTI");
if(oid == 0) oid = mSession.i("last_order_id");

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao(siteId);
PaymentDao payment = new PaymentDao();

CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

String payUrl = "/order/payment.jsp?oek=" + order.getOrderEk(oid, userId);

//목록-주문항목
DataSet list = orderItem.getOrderItems(userId, null, oid);
//DataSet list = orderItem.getOrderItems(userId, null, oid, isSiteTemplate);

//제한-수강인원제한
if(orderItem.isUserLimit) {
	m.jsAlert(_message.get(orderItem.goCartMessage));
	return;
}

if("00".equals(resultCode)) {

	DataSet info = order.find("id = " + oid + " AND status = -99");
	if(!info.next()) {
		m.jsAlert(_message.get("alert.order.nodata"));
		m.jsReplace(payUrl);
		return;
	}

	boolean isDBOK = true;
	boolean bankAccount = false;
	int newPaymentId = 0;

	String mid = siteinfo.s("pg_id");					// 가맹점 ID 수신 받은 데이터로 설정
	String tid= m.rs("P_TID");					// 취소 요청 tid에 따라서 유동적(가맹점 수정후 고정)
	String reqUrl = m.rs("P_REQ_URL");						// 승인요청 API url(수신 받은 값으로 설정, 임의 세팅 금지)

	if("".equals(tid) || "".equals(reqUrl)) {
		m.jsAlert(_message.get("alert.payment.noresult"));
		m.jsReplace(payUrl);
		return;
	}
						
	Http http = new Http(reqUrl);
	http.setParam("P_MID", mid);					// 필수
	http.setParam("P_TID", tid);					// 필수
	String ret = http.send("POST");

	m.log("inipay", ret.trim());

	DataSet resultMap = new DataSet();
	resultMap.addRow();

	String arr[] = ret.split("&");
	for(int i=0; i<arr.length; i++) {
		String arr2[] = arr[i].split("=");
		if(arr2.length == 2) resultMap.put(arr2[0], arr2[1].trim());	
	}
								
	if("00".equals(resultMap.s("P_STATUS"))) {	//결제보안 강화 2016-05-18

		bankAccount = "VBANK".equals(resultMap.s("P_TYPE"));

		newPaymentId = payment.getSequence();

		payment.item("id", newPaymentId);
		payment.item("site_id", siteId);
		payment.item("pg_nm", "inicis");
		payment.item("reg_date", m.time("yyyyMMddHHmmss"));

		payment.item("oid", resultMap.s("P_OID")); //주문번호
		payment.item("mid", resultMap.s("P_MID"));
		payment.item("tid", resultMap.s("P_TID")); //거래번호
		payment.item("paytype", resultMap.s("P_TYPE")); //결제방법(지불수단)
		payment.item("respcode", resultMap.s("P_STATUS"));
		payment.item("respmsg", resultMap.s("P_RMESG1"));
		payment.item("amount", resultMap.s("P_AMT"));
		payment.item("buyer", resultMap.s("P_UNAME"));
		payment.item("buyeremail", resultMap.s("P_EMAIL"));
		payment.item("buyerphone", resultMap.s("P_MOBILE"));
		payment.item("productinfo", resultMap.s("P_GOODS"));

		String[] banks = {"03=>기업은행","04=>국민은행","05=>KEB하나(외한)은행","11=>농협중앙","20=>우리은행","23=>SC제일은행","26=>신한은행","27=>시티은행","31=>대구은행","32=>부산은행","34=>광주은행","37=>전북은행","38=>강원은행","39=>경남은행","40=>충북은행","45=>새마을금고","53=>씨티은행","71=>우체국","81=>KEB하나은행"};

		payment.item("paydate", resultMap.s("P_AUTH_DT")); //승인날짜
		payment.item("timestamp", resultMap.s("P_AUTH_DT")); //승인시간
		payment.item("accountnum", resultMap.s("P_VACT_NUM")); //입금계좌번호
		payment.item("financecode", resultMap.s("P_VACT_BANK_CODE")); //은행코드			
		payment.item("financename", m.getItem(resultMap.s("P_VACT_BANK_CODE"), banks)); //은행명
		payment.item("accountowner", resultMap.s("P_VACT_NAME")); //예금주
		payment.item("saowner", resultMap.s("P_VACT_NAME")); //예금주
		payment.item("payer", resultMap.s("P_UNAME")); //송금자명

		payment.item("cashreceiptcode", resultMap.s("P_CSHR_CODE")); //현금영수증 발급결과
		payment.item("cashreceiptkind", resultMap.s("P_CSHR_TYPE")); //현금영수증 발급구분코드 (0-소득공제용, 1-지출증빙용)

		payment.item("telno", resultMap.s("P_HPP_NUM")); //휴대폰번호

		payment.item("cardnum", resultMap.s("P_CARD_NUM")); //카드번호					
		payment.item("financeauthnum", resultMap.s("P_AUTH_NO")); //승인번호
		payment.item("cardnointyn", resultMap.s("P_CARD_INTEREST")); //할부요형

		if(!payment.insert()) isDBOK = false;

		if(isDBOK) {
			order.item("pay_date", m.time());
			order.item("status", bankAccount ? 2 : 1); // 무통장입금은 2
			if(!order.update("id = " + oid + " AND status = -99")) isDBOK = false;
		}
		
		//갱신-주문항목
		if(isDBOK) {
			orderItem.item("order_id", oid);
			orderItem.item("status", bankAccount ? 2 : 1); // 무통장입금은 2
			if(!orderItem.update("id IN (" + info.s("items") + ")")) isDBOK = false;		
		}
		
		if(isDBOK == false) {
			//롤백 기능이 없어서 주문을 입금 대기 상태로 둠.
			order.item("status", 2);
			order.update("id = " + oid);

			m.jsAlert(_message.get("alert.order.error_wrapup"));
			m.jsReplace(payUrl);
			return;
		}

		//주문처리
		boolean orderProcessOk = order.process(oid);

		//프로세스 false : 결제취소, 주문정보삭제
		if(!orderProcessOk) {
			//이니페이 모바일 결제 취소가 없어 주문을 결제취소 상태로

			//주문, 주문항목 결제취소 처리
			order.rollback(oid, list);

			m.jsAlert(_message.get("alert.order.error_wrapup"));
			m.jsReplace(payUrl);
			return;
		}

		//발송
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

		if(bankAccount) {
			p.setVar("payment", payment.find("id = " + newPaymentId + " AND oid = " + oid));
			mail.send(siteinfo, uinfo, "account", p);
			smsTemplate.sendSms(siteinfo, uinfo, "account", p);
		} else {
			mail.send(siteinfo, uinfo, "payment", p);
			smsTemplate.sendSms(siteinfo, uinfo, "payment", p, "P");
		}

		//정상처리시 결과페이지로
		String eKey = m.encrypt(oid + userId + "__LMS2014");
		m.jsReplace("payment_complete.jsp?ek=" + eKey + "&oid=" + m.encode(""+oid), "parent");
		return;

	} else {
		m.jsAlert(_message.get("alert.payment.canceled_by_error"));
		m.jsReplace(payUrl);
		return;
	}

} else {
	//if("01".equals(resultCode)) resultMsg = "사용자가 주문을 취소하였습니다.";
	if("".equals(resultMsg)) resultMsg = "주문이 취소되었습니다.";
	m.jsAlert(resultMsg + " (" + resultCode + ")");
	m.jsReplace(payUrl);
	return;
}

%>