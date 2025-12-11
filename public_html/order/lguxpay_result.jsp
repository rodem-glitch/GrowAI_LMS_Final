<%@ page contentType="text/html; charset=utf-8" %><%@ page import="lgdacom.XPayClient.XPayClient,org.apache.commons.httpclient.HttpException"%><%@ include file="../init.jsp" %><%
	
String LGD_RESPCODE = m.rs("LGD_RESPCODE");
String LGD_RESPMSG 	= m.rs("LGD_RESPMSG");
int oid = m.ri("LGD_OID");

UserDao user = new UserDao();
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao(siteId);
PaymentDao payment = new PaymentDao();

CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

//목록-주문항목
DataSet list = orderItem.getOrderItems(userId, null, oid);
//DataSet list = orderItem.getOrderItems(userId, null, oid, isSiteTemplate);

//제한-수강인원제한
if(orderItem.isUserLimit) {
	m.jsAlert(_message.get(orderItem.goCartMessage));
	return;
}

if("0000".equals(LGD_RESPCODE)) {

	DataSet info = order.find("id = " + oid + " AND status = -99");
	if(!info.next()) {
		m.jsAlert(_message.get("alert.order.nodata"));
		m.js("parent.payment_close()");
		return;
	}

	DataSet uinfo = user.find("id = " + info.i("user_id") + " AND status = 1");
	if(!uinfo.next()) { m.jsError(_message.get("alert.member.nodata")); return; }
	uinfo.put("mobile_conv", !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "");

	boolean isDBOK = true;
	boolean bankAccount = "SC0040".equals(m.rs("LGD_PAYTYPE"));
	String platform = ("lgdacomxpay".equals(siteinfo.s("pg_id")) || siteinfo.b("pg_test_yn")) ? "test" : "service";
	String mid = ("test".equals(platform) ? "t" : "") + siteinfo.s("pg_id");
	int newPaymentId = 0;

	//LGU 모듈
	XPayClient xpay = new XPayClient();
	boolean isInitOK = xpay.Init(docRoot + "/../lgdacom", platform);
	if(!isInitOK) { //API 초기화 실패
		m.jsAlert(_message.get("alert.payment.error_init"));
		m.js("parent.payment_close()");
		return;
	} else {
		try {
			xpay.Init_TX(mid);
			xpay.Set("LGD_TXNAME", "PaymentByKey");
			xpay.Set("LGD_PAYKEY", m.rs("LGD_PAYKEY")); //인증 후 자동 생성됨.
			xpay.Set("LGD_AMOUNTCHECKYN", "Y");
			xpay.Set("LGD_AMOUNT", info.s("pay_price"));
		} catch(RuntimeException ioe) {
			m.jsAlert("LG유플러스 제공 API를 사용할 수 없습니다. 환경파일 설정을 확인해 주시기 바랍니다.\\n" + ioe.getMessage());
			m.js("parent.payment_close()");
			return;
		} catch(Exception e) {
			m.jsAlert("LG유플러스 제공 API를 사용할 수 없습니다. 환경파일 설정을 확인해 주시기 바랍니다.\\n" + e.getMessage());
			m.js("parent.payment_close()");
			return;
		}
	}

	//결제결과
	if(xpay.TX()) {
		//필드
		String[] fields = {
			"LGD_BUYER"
			, "LGD_MID"
			, "LGD_FINANCEAUTHNUM"
			, "LGD_CARDNUM"
			, "LGD_PAYDATE"
			, "LGD_AMOUNT"
			, "LGD_ESCROWYN"
			, "LGD_PAYTYPE"
			, "LGD_TIMESTAMP"
			, "LGD_HASHDATA"
			, "LGD_BUYEREMAIL"
			, "LGD_TID"
			, "LGD_PRODUCTINFO"
			, "LGD_DELIVERYINFO"
			, "LGD_CARDINSTALLMONTH"
			, "LGD_VANCODE"
			, "LGD_PRODUCTCODE"
			, "LGD_CARDGUBUN2"
			, "LGD_CARDGUBUN1"
			, "LGD_BUYERID"
			, "LGD_BUYERSSN"
			, "LGD_BILLKEY"
			, "LGD_FINANCECODE"
			, "LGD_RESPMSG"
			, "LGD_CARDNOINTYN"
			, "LGD_PCANCELSTR"
			, "LGD_TRANSAMOUNT"
			, "LGD_EXCHANGERATE"
			, "LGD_HASHDATA_BILLKEY"
			, "LGD_BUYERADDRESS"
			, "LGD_RECEIVERPHONE"
			, "LGD_OID"
			, "LGD_FINANCENAME"
			, "LGD_PCANCELFLAG"
			, "LGD_CARDACQUIRER"
			, "LGD_RECEIVER"
			, "LGD_RESPCODE"
			, "LGD_BUYERPHONE"
			, "LGD_CASFLAG"
			, "LGD_CASHRECEIPTCODE"
			, "LGD_ACCOUNTNUM"
			, "LGD_CASHRECEIPTKIND"
			, "LGD_CASCAMOUNT"
			, "LGD_SAOWNER"
			, "LGD_CASTAMOUNT"
		};

		for(int i=0; i<fields.length; i++) {
			payment.item(m.replace(fields[i].toLowerCase(), "lgd_", ""), xpay.Response(fields[i], 0));
		}

		newPaymentId = payment.getSequence();
		payment.item("id", newPaymentId);
		payment.item("site_id", siteId);
		payment.item("pg_nm", "lgu");
		payment.item("reg_date", m.time("yyyyMMddHHmmss"));
		if(!payment.insert()) isDBOK = false;

		if(!"0000".equals(xpay.m_szResCode)) { //최종결제요청 결과 성공 DB처리
			m.jsAlert(_message.get("alert.payment.canceled_by_error") + " [" + xpay.m_szResCode + "] [2]\\n" + xpay.Response("LGD_RESPMSG", 0));
			m.js("parent.payment_close()");
			return;
		}

		bankAccount = "SC0040".equals(xpay.Response("LGD_PAYTYPE", 0));
		
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
			xpay.Rollback("상점 DB처리 실패로 인하여 Rollback 처리 ["
				+ "TID:" + xpay.Response("LGD_TID", 0)
				+ ", MID:" + xpay.Response("LGD_MID", 0)
				+ ", OID:" + xpay.Response("LGD_OID", 0)
				+ "]"
			);

			//자동취소결과 업데이트
			payment.clear();
			payment.item("cancel_code", xpay.Response("LGD_RESPCODE", 0));
			payment.item("cancel_msg", xpay.Response("LGD_RESPMSG", 0));
			payment.update("id = " + newPaymentId + "");

			//주문정보 삭제
			order.clear();
			order.item("status", -1);
			order.update("id = " + oid);

			m.jsAlert(_message.get("alert.payment.canceled_by_error"));
			m.js("parent.payment_close()");
			return;
		}

		//주문처리
		isDBOK = order.process(oid);

		//프로세스 false : 결제취소, 주문정보삭제
		if(isDBOK == false) {
			//결제취소처리
			xpay.Rollback("상점 DB처리 실패로 인하여 Rollback 처리 ["
					+ "TID:" + xpay.Response("LGD_TID", 0)
					+ ", MID:" + xpay.Response("LGD_MID", 0)
					+ ", OID:" + xpay.Response("LGD_OID", 0)
					+ "]"
			);

			//자동취소결과 업데이트
			payment.clear();
			payment.item("cancel_code", xpay.Response("LGD_RESPCODE", 0));
			payment.item("cancel_msg", xpay.Response("LGD_RESPMSG", 0));
			payment.update("id = " + newPaymentId + "");

			//주문, 주문항목 결제취소 처리
			order.rollback(oid, list);

			m.jsAlert(_message.get("alert.payment.canceled_by_error"));
			m.js("parent.payment_close()");
			return;
		}

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
		String eKey = m.encrypt(oid + uinfo.i("id") + "__LMS2014");
		m.jsReplace("payment_complete.jsp?ek=" + eKey + "&oid=" + m.encode(""+oid), "parent");
		return;

	} else {
		m.jsAlert(_message.get("alert.payment.canceled_by_error") + " [3]\\n" + xpay.Response("LGD_RESPMSG", 0));
		m.js("parent.payment_close()");
		return;
	} // -- xpay.TX()

} else {

%>
<html>
<head>
	<script type="text/javascript">
		function setLGDResult() {
			if( parent.LGD_window_type == "iframe" ){
				parent.payment_return();
			} else {
				opener.payment_return();
				window.close();
			}
		}
	</script>
</head>
<body onload="setLGDResult()">
	<table align="center" width="100%" height="100%">
	<tr>
		<td align="center"><img src="/common/images/paying.png"></td>
	</tr>
	</table>
<%
   	Map parameters = request.getParameterMap();
    for (Iterator it = parameters.keySet().iterator(); it.hasNext(); ) {
        String name = (String)it.next();
        int i = ((String[])parameters.get(name)).length;
        for( int k = 0 ; k<i ; k++){
            String value = ((String[]) parameters.get(name))[k];
    		out.println("<input type='hidden' name='" + name + "' id='" + name + "' value='" + value + "'>" );
        }
   	}
%>
</body>
</html>
<% } %>