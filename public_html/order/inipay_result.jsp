<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%
	
String resultCode = m.rs("resultCode");
String resultMsg 	= m.rs("resultMsg");
int oid = m.ri("orderNumber");

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

if("0000".equals(resultCode)) {

	DataSet info = order.find("id = " + oid + " AND status = -99");
	if(!info.next()) {
		m.jsAlert(_message.get("alert.order.nodata"));
		m.jsReplace(payUrl);
		return;
	}

	boolean isDBOK = true;
	boolean bankAccount = "VBank".equals(m.rs("payMethod"));
	int newPaymentId = 0;

	String mid 		= siteinfo.s("pg_id");					// 가맹점 ID 수신 받은 데이터로 설정
	String signKey	= siteinfo.s("pg_key");					// 가맹점에 제공된 키(이니라이트키) (가맹점 수정후 고정) !!!절대!! 전문 데이터로 설정금지
	String timestamp= m.time();								// util에 의해서 자동생성
	String charset 	= "UTF-8";								// 리턴형식[UTF-8,EUC-KR](가맹점 수정후 고정)
	String format 	= "JSON";								// 리턴형식[XML,JSON,NVP](가맹점 수정후 고정)
	String authToken= m.rs("authToken");					// 취소 요청 tid에 따라서 유동적(가맹점 수정후 고정)
	String authUrl	= m.rs("authUrl");						// 승인요청 API url(수신 받은 값으로 설정, 임의 세팅 금지)
	String netCancel= m.rs("netCancelUrl");					// 망취소 API url(수신 받은 값으로 설정, 임의 세팅 금지)
	String ackUrl = m.rs("checkAckUrl");					// 가맹점 내부 로직 처리후 최종 확인 API URL(수신 받은 값으로 설정, 임의 세팅 금지)		
	String cardnum = m.rs("cardnum");						// 갤러리아 카드번호(카드끝자리 '*' 처리) 2016-01-12
	String signature = m.encrypt("authToken=" + authToken + "&timestamp=" + timestamp, "SHA-256");
						
	Http http = new Http(authUrl);
	http.setParam("mid", mid);					// 필수
	http.setParam("authToken", authToken);		// 필수
	http.setParam("signature", signature);		// 필수
	http.setParam("timestamp", timestamp);		// 필수
	http.setParam("charset", charset);			// default=UTF-8
	http.setParam("format", format);			// default=XML
	http.setParam("price", info.s("pay_price"));    // 가격위변조체크기능 (선택사용)
	String ret = http.send("POST");

	m.log("inipay", ret);

	DataSet resultMap = Json.decode(ret);
								
	if(resultMap.next() && "0000".equals(resultMap.s("resultCode"))) {	//결제보안 강화 2016-05-18

		bankAccount = "VBank".equals(resultMap.s("payMethod"));

		newPaymentId = payment.getSequence();

		payment.item("id", newPaymentId);
		payment.item("site_id", siteId);
		payment.item("pg_nm", "inicis");
		payment.item("reg_date", m.time("yyyyMMddHHmmss"));

		payment.item("oid", resultMap.s("MOID")); //주문번호
		payment.item("mid", resultMap.s("mid"));
		payment.item("tid", resultMap.s("tid")); //거래번호
		payment.item("paytype", resultMap.s("payMethod")); //결제방법(지불수단)
		payment.item("respcode", resultMap.s("resultCode"));
		payment.item("respmsg", resultMap.s("resultMsg"));
		payment.item("amount", resultMap.s("TotPrice"));
		payment.item("buyer", resultMap.s("buyerName"));
		payment.item("buyeremail", resultMap.s("buyerEmail"));
		payment.item("buyerphone", resultMap.s("buyerTel"));
		payment.item("productinfo", resultMap.s("goodsName"));

		payment.item("paydate", resultMap.s("applDate") + resultMap.s("applTime")); //승인날짜
		payment.item("timestamp", resultMap.s("applDate") + resultMap.s("applTime")); //승인시간
		payment.item("accountnum", resultMap.s("VACT_Num")); //입금계좌번호
		payment.item("financecode", resultMap.s("VACT_BankCode")); //은행코드			
		payment.item("financename", resultMap.s("vactBankName")); //은행명
		payment.item("accountowner", resultMap.s("VACT_Name")); //예금주
		payment.item("saowner", resultMap.s("VACT_Name")); //예금주
		payment.item("payer", resultMap.s("VACT_InputName")); //송금자명
		//payment.item("id", resultMap.s("VACT_Date")); //송금일자
		//payment.item("id", resultMap.s("VACT_Time")); //송금시간

		//payment.item("financecode", resultMap.s("ACCT_BankCode")); //은행코드
		payment.item("cashreceiptcode", resultMap.s("CSHR_ResultCode")); //현금영수증 발급결과
		payment.item("cashreceiptkind", resultMap.s("CSHR_Type")); //현금영수증 발급구분코드 (0-소득공제용, 1-지출증빙용)

		//payment.item("id", resultMap.s("HPP_Corp")); //통신사
		//payment.item("id", resultMap.s("payDevice")); //결제장치					 
		payment.item("telno", resultMap.s("HPP_Num")); //휴대폰번호

		payment.item("cardnum", resultMap.s("CARD_Num")); //카드번호					
		payment.item("financeauthnum", resultMap.s("applNum")); //승인번호
		payment.item("cardinstallmonth", resultMap.s("CARD_Quota")); //할부기간
		payment.item("cardnointyn", resultMap.s("CARD_Interest")); //할부요형

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
			//결제취소처리
			http.setUrl(netCancel);
			ret = http.send("POST");

			m.log("inipay", ret);
			resultMap = Json.decode(ret);
			resultMap.next();

			//자동취소결과 업데이트
			payment.clear();
			payment.item("cancel_code", resultMap.s("resultCode"));
			payment.item("cancel_msg", resultMap.s("resultMsg"));
			payment.update("id = " + newPaymentId + "");

			//주문정보 삭제
			order.clear();
			order.item("status", -1);
			order.update("id = " + oid);

			m.jsAlert(_message.get("alert.payment.canceled_by_error"));
			m.jsReplace(payUrl);
			return;
		}

		//주문처리
		isDBOK = order.process(oid);

		//프로세스 false : 결제취소, 주문정보삭제
		if(isDBOK == false) {
			//결제취소처리
			http.setUrl(netCancel);
			ret = http.send("POST");

			m.log("inipay", ret);
			resultMap = Json.decode(ret);
			resultMap.next();

			//자동취소결과 업데이트
			payment.clear();
			payment.item("cancel_code", resultMap.s("resultCode"));
			payment.item("cancel_msg", resultMap.s("resultMsg"));
			payment.update("id = " + newPaymentId + "");

			//주문, 주문항목 결제취소 처리
			order.rollback(oid, list);

			m.jsAlert(_message.get("alert.payment.canceled_by_error"));
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
	m.jsAlert(resultMsg + " (" + resultCode + ")");
	m.jsReplace(payUrl);
	//m.jsReplace(payUrl);
	return;
}

%>