<%@ page import="javax.xml.ws.http.HTTPException" %>
<%@ page import="malgnsoft.json.*" %>
<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//제한
if(!m.isPost()) { m.jsAlert("올바른 접근이 아닙니다."); return; }

//기본키
int oid = m.ri("YMDR_TRACK_ID");
if(1 > oid) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//제한-사이트설정
String paymentKey = SiteConfig.s("pay_ymdr_key");
if("".equals(paymentKey)) { m.jsAlert("사용하지 않는 결제수단입니다."); return; }

//변수
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao(siteId);
PaymentDao payment = new PaymentDao();

CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

//정보-주문
DataSet info = order.find("id = " + oid + " AND status = -99");
if(!info.next()) {
	m.jsAlert("주문정보를 찾을 수 없습니다.");
	return;
}

//제한-해시데이터
if("inicis".equals(siteinfo.s("pg_nm"))) {
	if(!m.rs("YMDR_HASHDATA").equals(m.encrypt("oid=" + oid + "&price=" + m.rs("YMDR_AMOUNT") + "&timestamp=" + m.rs("YMDR_TIMESTAMP"), "SHA-256"))) {
		m.jsAlert("올바른 주문정보가 아닙니다.");
		return;
	}
} else {
	if(!m.rs("YMDR_HASHDATA").equals(m.encrypt(m.rs("YMDR_MID") + oid + m.rs("YMDR_AMOUNT") + m.rs("YMDR_TIMESTAMP") + siteinfo.s("pg_key")))) {
		m.jsAlert("올바른 주문정보가 아닙니다.");
		return;
	}
}

//정보-파라미터
DataSet plist = new DataSet();
plist.addRow();
plist.put("trackId", oid);
plist.put("card", m.rs("YMDR_CARD"));
plist.put("amount", m.rs("YMDR_AMOUNT"));
plist.put("ssn", m.rs("YMDR_SSN"));
plist.put("userId", m.rs("YMDR_USER_ID"));
plist.put("telNo", m.rs("YMDR_TEL_NO"));
String params = plist.serialize();
params = "{\"purchase\": " + params.substring(1, params.length() - 1) + " }";

//변수
Json json = new Json();

//처리
try {
	Http http = new Http("https://api.ymdr.kr/api/purchase");
	//http.setDebug(out);
	http.setData(params);
	http.setHeader("Content-type", "application/json");
	http.setHeader("Authorization", SiteConfig.s("pay_ymdr_key"));

	String ret = http.send("POST");
	//m.log("ymdr", m.stripTags(ret));
	m.log("ymdr", ret);
	json.setJson(ret);
}
catch(HTTPException httpe) {
	m.errorLog("HTTPException : " + httpe.getMessage(), httpe);
	m.jsAlert("결제하는 중 오류가 발생했습니다.");
	return;
}
catch(JSONException jsone) {
	m.errorLog("JSONException : " + jsone.getMessage(), jsone);
	m.jsAlert("결제하는 중 오류가 발생했습니다.");
	return;
}
catch(Exception e) {
	m.errorLog("Exception : " + e.getMessage(), e);
	m.jsAlert("결제하는 중 오류가 발생했습니다.");
	return;
}

//정보-결과
DataSet resultMap = json.getDataSet("//result");
if(!resultMap.next()) { m.jsAlert("결제응답정보가 없습니다."); return; }

//변수
String resultCode = resultMap.s("code");
String resultMsg = resultMap.s("message") + " (" + resultMap.s("advancedMessage") + ")";

if("00".equals(resultCode)) {

	DataSet purchaseMap = json.getDataSet("//purchaseResult");
	DataSet settleMap = json.getDataSet("//purchaseResult/settleResult");

	if(purchaseMap.next()) {	//결제보안 강화 2016-05-18

		boolean isDBOK = true;
		int newPaymentId = payment.getSequence();

		payment.item("id", newPaymentId);
		payment.item("site_id", siteId);
		payment.item("pg_nm", "ymdr");
		payment.item("reg_date", m.time("yyyyMMddHHmmss"));

		payment.item("oid", purchaseMap.s("trackId")); //주문번호
		payment.item("mid", paymentKey);
		payment.item("tid", purchaseMap.s("trnNo")); //거래번호
		payment.item("paytype", "ymdr"); //결제방법(지불수단)
		payment.item("respcode", resultCode);
		payment.item("respmsg", resultMsg);
		payment.item("amount", purchaseMap.s("amount"));
		payment.item("buyer", m.rs("YMDR_USER_ID"));
		payment.item("buyeremail", "");
		payment.item("buyerphone", m.rs("YMDR_TEL_NO"));
		payment.item("productinfo", m.rs("YMDR_DESCRIPTION"));

		payment.item("paydate", m.time("yyyyMMddHHmmss", resultMap.s("create"))); //승인날짜
		payment.item("timestamp", m.time("yyyyMMddHHmmss", resultMap.s("create"))); //승인시간
		payment.item("accountnum", ""); //입금계좌번호
		payment.item("financecode", ""); //은행코드
		payment.item("financename", ""); //은행명
		payment.item("accountowner", ""); //예금주
		payment.item("saowner", ""); //예금주
		payment.item("payer", ""); //송금자명
		//payment.item("id", purchaseMap.s("VACT_Date")); //송금일자
		//payment.item("id", purchaseMap.s("VACT_Time")); //송금시간

		//payment.item("financecode", purchaseMap.s("ACCT_BankCode")); //은행코드
		payment.item("cashreceiptcode", ""); //현금영수증 발급결과
		payment.item("cashreceiptkind", ""); //현금영수증 발급구분코드 (0-소득공제용, 1-지출증빙용)

		//payment.item("id", purchaseMap.s("HPP_Corp")); //통신사
		//payment.item("id", purchaseMap.s("payDevice")); //결제장치					 
		payment.item("telno", m.rs("YMDR_TEL_NO")); //휴대폰번호

		payment.item("cardnum", m.rs("YMDR_CARD")); //카드번호					
		payment.item("financeauthnum", purchaseMap.s("authCode")); //승인번호
		payment.item("cardinstallmonth", ""); //할부기간
		payment.item("cardnointyn", ""); //할부요형

		if(!payment.insert()) isDBOK = false;

		if(isDBOK) {
			order.item("pay_date", m.time());
			order.item("status", 1);
			if(!order.update("id = " + oid + " AND status = -99")) isDBOK = false;
		}
		
		//갱신-주문항목
		if(isDBOK) {
			orderItem.item("order_id", oid);
			orderItem.item("status", 1);
			if(!orderItem.update("id IN (" + info.s("items") + ")")) isDBOK = false;		
		}
		
		if(isDBOK == false) {
			//결제취소처리
			plist.removeAll();
			plist.addRow();
			plist.put("trackId", purchaseMap.s("trackId") + "_R" + m.time("yyyyMMddHHmmss"));
			plist.put("description", "DB등록실패");
			plist.put("amount", purchaseMap.s("amount"));
			plist.put("originTrnNo", purchaseMap.s("trnNo"));
			plist.put("originTrackId", purchaseMap.s("trackId"));
			plist.put("originTrnDate", m.time("yyyyMMdd", resultMap.s("create")));
			params = plist.serialize();
			params = "{\"refund\": " + params.substring(1, params.length() - 1) + " }";

			//처리
			try {
				Http http = new Http("https://api.ymdr.kr/api/refund");
				//http.setDebug(out);
				http.setData(params);
				http.setHeader("Content-type", "application/json");
				http.setHeader("Authorization", SiteConfig.s("pay_ymdr_key"));

				String ret = http.send("POST");
				//m.log("ymdr", m.stripTags(ret));
				m.log("ymdr", ret);
				json.setJson(ret);
			}
			catch(HTTPException httpe) {
				m.errorLog("HTTPException : " + httpe.getMessage(), httpe);
				m.jsAlert("취소처리하는 중 오류가 발생했습니다.");
				//return;
			}
			catch(JSONException jsone) {
				m.errorLog("JSONException : " + jsone.getMessage(), jsone);
				m.jsAlert("취소처리하는 중 오류가 발생했습니다.");
				//return;
			}
			catch(Exception e) {
				m.errorLog("Exception : " + e.getMessage(), e);
				m.jsAlert("취소처리하는 중 오류가 발생했습니다.");
				//return;
			}

			//정보-결과
			resultMap = json.getDataSet("//result");
			resultMap.next();

			//자동취소결과 업데이트
			payment.clear();
			payment.item("cancel_code", resultMap.s("code"));
			payment.item("cancel_msg", resultMap.s("message") + " (" + resultMap.s("advancedMessage") + ")");
			payment.update("id = " + newPaymentId + "");

			//주문정보 삭제
			order.clear();
			order.item("status", -1);
			order.update("id = " + oid);

			m.jsAlert("처리하는 중 오류가 발생하여 결제가 자동취소 되었습니다.(DB ERROR)");
			return;
		}

		//주문처리
		order.process(oid);

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
		mail.send(siteinfo, uinfo, "payment", p);
		smsTemplate.sendSms(siteinfo, uinfo, "payment", p, "P");

		//정상처리시 결과페이지로
		String eKey = m.encrypt(oid + userId + "__LMS2014");
		m.jsReplace("payment_complete.jsp?ek=" + eKey + "&oid=" + m.encode(""+oid), "parent");
		return;

	} else {
		m.jsAlert("처리하는 중 오류가 발생하여 결제가 자동취소 되었습니다.");
		return;
	}

} else {
	m.jsAlert(resultMsg + " (" + resultCode + ")");
	return;
}

%>