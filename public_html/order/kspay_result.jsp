<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String rcid		= m.rs("reCommConId");
String rctype	= m.rs("reCommType");
String rhash	= m.rs("reHash");

int oid = mSession.i("last_order_id");
boolean isMobile = m.isMobile();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao(siteId);
PaymentDao payment = new PaymentDao();

CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

String payUrl = "/mypage/payment.jsp?oek=" + order.getOrderEk(oid, userId);

if(!"".equals(rcid)) {

	DataSet info = order.find("id = " + oid + " AND status = -99");
	if(!info.next()) {
		m.jsAlert(_message.get("alert.order.nodata"));
		if(isMobile) m.jsReplace(payUrl);
		else m.js("window.close()");
		return;
	}

	boolean isDBOK = true;
	boolean bankAccount = "VBank".equals(rctype);
	int newPaymentId = 0;

	String[] params = {"authyn", "trno", "trddt", "trdtm", "amt", "authno", "msg1", "msg2", "ordno", "isscd", "aqucd", "result", "resultcd", "temp_v", "halbu", "cbtrno", "cbauthno"};

	String url = "http://kspay.ksnet.to/store/KSPayFlashV1.3/web_host/recv_post.jsp";
	if(isMobile) url = "http://kspay.ksnet.to/store/mb2/web_host/recv_post.jsp";

	Http http = new Http(url);
	http.setEncoding("euc-kr");
	http.setParam("sndCommConId", rcid);
	http.setParam("sndActionType", "1");
	http.setParam("sndRpyParams", m.join("`", params));

	String ret = http.send("POST");
	m.log("kspay", ret.trim());
	String[] arr = ret.substring(1).split("`");

	DataSet resultMap = new DataSet();
	resultMap.addRow();
	for(int i=0; i<params.length; i++) {
		resultMap.put(params[i], arr[i].trim());
	}

	m.log("kspay", resultMap.toString());

	if("O".equals(resultMap.s("authyn"))) {

		bankAccount = "6001".equals(resultMap.s("result"));

		newPaymentId = payment.getSequence();

		payment.item("id", newPaymentId);
		payment.item("site_id", siteId);
		payment.item("pg_nm", "ksnet");
		payment.item("reg_date", m.time("yyyyMMddHHmmss"));

		payment.item("oid", resultMap.s("ordno")); //주문번호
		payment.item("mid", siteinfo.s("pg_id"));
		payment.item("tid", resultMap.s("trno")); //거래번호
		payment.item("paytype", resultMap.s("result")); //결제방법(지불수단)
		payment.item("respcode", resultMap.s("resultcd"));
		payment.item("respmsg", resultMap.s("msg1") +","+ resultMap.s("msg2"));
		payment.item("amount", resultMap.s("amt"));
		payment.item("hashdata", rhash);

		String[] banks = {"03=>기업은행","04=>국민은행","05=>KEB하나(외한)은행","11=>농협중앙","20=>우리은행","23=>SC제일은행","26=>신한은행","27=>시티은행","31=>대구은행","32=>부산은행","34=>광주은행","37=>전북은행","38=>강원은행","39=>경남은행","40=>충북은행","45=>새마을금고","53=>씨티은행","71=>우체국","81=>KEB하나은행"};

		payment.item("paydate", resultMap.s("trddt") + resultMap.s("trdtm")); //승인날짜
		payment.item("timestamp", resultMap.s("trddt") + resultMap.s("trdtm")); //승인시간
		payment.item("accountnum", resultMap.s("isscd")); //입금계좌번호
		payment.item("financecode", resultMap.s("authno")); //은행코드			
		payment.item("financename", m.getItem(resultMap.s("authno"), banks)); //은행명

		payment.item("cardnum", resultMap.s("P_CARD_NUM")); //카드번호					
		payment.item("financeauthnum", resultMap.s("authno")); //승인번호
		payment.item("cardnointyn", resultMap.s("halbu")); //할부요형

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
			//주문정보 삭제
			order.item("status", 2);
			order.update("id = " + oid);

			m.jsAlert(_message.get("alert.order.error_wrapup"));
			if(isMobile) m.jsReplace(payUrl);
			else m.js("window.close()");

			return;
		}

		//주문처리
		order.process(oid);

		//메일발송
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
		String completeUrl = "payment_complete.jsp?ek=" + m.encrypt(oid + userId + "__LMS2014") + "&oid=" + m.encode(""+oid);
		
		if(isMobile) {
			m.jsReplace(completeUrl);
		} else {
			m.jsReplace(completeUrl, "opener");
			m.js("window.close()");
		}

		return;

	} else {
		m.jsAlert(_message.get("alert.order.error_wrapup"));
		if(isMobile) m.jsReplace(payUrl);
		else m.js("window.close()");
		return;
	}

} else {

	m.jsAlert(_message.get("alert.payment.canceled_by_user"));
	m.jsReplace(payUrl);
	return;
}

%>