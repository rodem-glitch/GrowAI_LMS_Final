<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%@ page import="com.allat.util.AllatUtil" %><%

m.log("allat_result", m.reqMap("").toString());

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr("ktalk_");

//객체
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao(siteId);
PaymentDao payment = new PaymentDao();
AllatUtil util = new AllatUtil();

MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
KtalkDao ktalk = new KtalkDao(siteId);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId);

//기본키
int oid = f.getInt("allat_order_no");
if(0 == oid) {
	m.jsAlert(_message.get("alert.common.required_key"));
	return;
}

//정보
DataSet info = order.find("site_id = ? AND user_id = ? AND status = -99 AND id = ?", new Integer[] {siteId, userId, oid});
if(!info.next()) {
	m.jsAlert(_message.get("alert.order.nodata"));
	return;
}

//목록
DataSet list = orderItem.getOrderItems(userId, null, oid);
int payPrice = orderItem.payPrice;
String productName = orderItem.productName;

//제한-수강인원제한
if(orderItem.isUserLimit) {
	m.jsAlert(_message.get(orderItem.goCartMessage));
	return;
}

//배송정보
String deliveryInfo[] = order.getDeliveryInfo(list);
String deliveryType = deliveryInfo[0];
int deliveryPrice = Integer.parseInt(deliveryInfo[1]);
int deliveryFreePrice = SiteConfig.getInt("delivery_free_price");

//배송비무료최소금액 초과시 배송비 무료
if(deliveryFreePrice > 0 && deliveryFreePrice <= payPrice) {
	deliveryType = "B";
	deliveryPrice = 0;
}

//상품명
productName = m.cutString(productName, 80);
if(list.size() >= 2) productName += " " + _message.get("payment.name.and") + " " + (list.size() - 1) + _message.get("payment.name.others");
if(deliveryPrice == 100000000) deliveryPrice = 0;
if(deliveryPrice > 0) payPrice += deliveryPrice;

//제한-금액
if(payPrice != f.getInt("allat_amt")) {
	m.jsAlert(_message.get("alert.order.abnormal"));
	return;
}

//변수
String sCrossKey = siteinfo.s("pg_key");
String sShopId = siteinfo.s("pg_id");
String sAmount = payPrice + "";

String sEncData = f.get("allat_enc_data");
String strReq = "allat_shop_id=" + sShopId + "&allat_amt=" + sAmount + "&allat_enc_data=" + sEncData + "&allat_cross_key=" + sCrossKey;

//통신
HashMap hm = null;
hm = util.approvalReq(strReq, "SSL");
if(hm == null) {
	m.jsAlert(_message.get("alert.order.noresult"));
	return;
}
m.log("allat_result_enc", hm.toString());

//변수-결과
String sReplyCd     = (String)hm.get("reply_cd");
String sReplyMsg    = (String)hm.get("reply_msg");
String payUrl = "/order/payment.jsp?oek=" + order.getOrderEk(oid, userId);

//처리
if(sReplyCd.equals("0000") || ("Y".equals(siteinfo.s("pg_test_yn")) && sReplyCd.equals("0001"))) {

	//변수-결과
	String sOrderNo        = hm.containsKey("order_no") ? (String)hm.get("order_no") : "";
	String sAmt            = hm.containsKey("amt") ? (String)hm.get("amt") : "";
	String sPayType        = hm.containsKey("pay_type") ? (String)hm.get("pay_type") : "";
	String sApprovalYmdHms = hm.containsKey("approval_ymdhms") ? (String)hm.get("approval_ymdhms") : "";
	String sSeqNo          = hm.containsKey("seq_no") ? (String)hm.get("seq_no") : "";
	String sApprovalNo     = hm.containsKey("approval_no") ? (String)hm.get("approval_no") : "";
	String sCardId         = hm.containsKey("card_id") ? (String)hm.get("card_id") : "";
	String sCardNm         = hm.containsKey("card_nm") ? (String)hm.get("card_nm") : "";
	String sSellMm         = hm.containsKey("sell_mm") ? (String)hm.get("sell_mm") : "";
	String sZerofeeYn      = hm.containsKey("zerofee_yn") ? (String)hm.get("zerofee_yn") : "";
	String sCertYn         = hm.containsKey("cert_yn") ? (String)hm.get("cert_yn") : "";
	String sContractYn     = hm.containsKey("contract_yn") ? (String)hm.get("contract_yn") : "";
	String sSaveAmt        = hm.containsKey("save_amt") ? (String)hm.get("save_amt") : "";
	String sBankId         = hm.containsKey("bank_id") ? (String)hm.get("bank_id") : "";
	String sBankNm         = hm.containsKey("bank_nm") ? (String)hm.get("bank_nm") : "";
	String sCashBillNo     = hm.containsKey("cash_bill_no") ? (String)hm.get("cash_bill_no") : "";
	String sCashApprovalNo = hm.containsKey("cash_approval_no") ? (String)hm.get("cash_approval_no") : "";
	String sEscrowYn       = hm.containsKey("escrow_yn") ? (String)hm.get("escrow_yn") : "";
	String sAccountNo      = hm.containsKey("account_no") ? (String)hm.get("account_no") : "";
	String sAccountNm      = hm.containsKey("account_nm") ? (String)hm.get("account_nm") : "";
	String sIncomeAccNm    = hm.containsKey("income_account_nm") ? (String)hm.get("income_account_nm") : "";
	String sIncomeLimitYmd = hm.containsKey("income_limit_ymd") ? (String)hm.get("income_limit_ymd") : "";
	String sIncomeExpectYmd= hm.containsKey("income_expect_ymd") ? (String)hm.get("income_expect_ymd") : "";
	String sCashYn         = hm.containsKey("cash_yn") ? (String)hm.get("cash_yn") : "";
	String sHpId           = hm.containsKey("hp_id") ? (String)hm.get("hp_id") : "";
	String sTicketId       = hm.containsKey("ticket_id") ? (String)hm.get("ticket_id") : "";
	String sTicketPayType  = hm.containsKey("ticket_pay_type") ? (String)hm.get("ticket_pay_type") : "";
	String sTicketNm       = hm.containsKey("ticket_nm") ? (String)hm.get("ticket_nm") : "";
	String sPointAmt       = hm.containsKey("point_amt") ? (String)hm.get("point_amt") : "";
	String sPartcancelYn   = hm.containsKey("partcancel_yn") ? (String)hm.get("partcancel_yn") : "";
	String sBCCertNo       = hm.containsKey("bc_cert_no") ? (String)hm.get("bc_cert_no") : "";
	String sCardNo         = hm.containsKey("card_no") ? (String)hm.get("card_no") : "";
	String sIspFullCardCd  = hm.containsKey("isp_full_card_cd") ? (String)hm.get("isp_full_card_cd") : "";
	String sCardType       = hm.containsKey("card_type") ? (String)hm.get("card_type") : "";
	String sBankAccountNm  = hm.containsKey("bank_account_nm") ? (String)hm.get("bank_account_nm") : "";

	boolean isCard = sApprovalNo != null && !"".equals(sApprovalNo);
	boolean isDBOK = true;
	boolean bankAccount = "VBANK".equals(sPayType);

	//등록-payment
	int newPaymentId = payment.getSequence();
	String financeName = isCard ? sCardNm : !"".equals(sBankNm) ? sBankNm : sIncomeAccNm;

	payment.item("id", newPaymentId);
	payment.item("site_id", siteId);
	payment.item("pg_nm", "allat");
	payment.item("respcode", sReplyCd);
	payment.item("respmsg", sReplyMsg);

	payment.item("mid", sShopId);
	payment.item("oid", sOrderNo); //주문번호
	payment.item("amount", sAmt);
	payment.item("tid", sSeqNo); //거래번호
	payment.item("paytype", sPayType); //결제방법(지불수단)
	payment.item("paydate", sApprovalYmdHms); //승인날짜
	payment.item("timestamp", sApprovalYmdHms); //승인시간
	payment.item("buyer", f.get("allat_buyer_nm"));
	payment.item("productinfo", productName);
	payment.item("buyeremail", f.get("allat_email_addr"));

	payment.item("financecode", isCard ? sCardId : sBankId); //은행코드
	payment.item("financename", financeName); //은행명
	payment.item("financeauthnum", sApprovalNo); //승인번호
	payment.item("escrowyn", sEscrowYn);
	payment.item("cashreceiptnum", sCashApprovalNo);
	payment.item("cashreceiptcode", sCashBillNo);

	payment.item("cardnum", sCardNo);
	payment.item("cardinstallmonth", sSellMm);
	payment.item("cardnointyn", sZerofeeYn);
	payment.item("pcancelflag", sPartcancelYn);

	payment.item("accountnum", sAccountNo); //입금계좌번호
	payment.item("accountowner", sBankAccountNm); //예금주
	payment.item("caslimitdate", sIncomeLimitYmd); //예금주
	payment.item("casexpectdate", sIncomeExpectYmd); //예금주
	payment.item("saowner", sBankAccountNm); //예금주
	payment.item("payer", sBankAccountNm); //송금자명

	payment.item("reg_date", m.time("yyyyMMddHHmmss"));

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
		m.log("inipay_fail", hm.toString());

		//자동취소결과 업데이트
		payment.clear();
		payment.item("cancel_code", "fail");
		payment.item("cancel_msg", "fail");
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
	boolean orderProcessOk = order.process(oid);

	//프로세스 false : 결제취소, 주문정보삭제
	if(!orderProcessOk) {

		//올앳 결제 취소
		HashMap<String, Object> resHm = util.cancelReq(strReq, "SSL"); //취소요청

		String replyCd   = (String)resHm.get("reply_cd");
		String replyMsg  = (String)resHm.get("reply_msg");
		StringBuilder sb = new StringBuilder();

		if(replyCd.equals("0000") || replyCd.equals("0001")){
			// reply_cd "0000" 일때만 성공 "0001" 테스트 성공
			String sCancelYMDHMS    = (String)resHm.get("cancel_ymdhms");
			String sPartCancelFlag  = (String)resHm.get("part_cancel_flag");
			String sRemainAmt       = (String)resHm.get("remain_amt");
			String payType         = (String)resHm.get("pay_type");

			sb.append("결과코드		: ").append(replyCd).append(", ");
			sb.append("결과메세지	: ").append(replyMsg).append(", ");
			sb.append("취소일시		: ").append(sCancelYMDHMS).append(", ");
			sb.append("취소구분		: ").append(sPartCancelFlag).append(", ");
			sb.append("잔액			: ").append(sRemainAmt).append(", ");
			sb.append("거래방식구분	: ").append(payType);
		}else{
			// reply_cd 가 "0000" 아닐때는 에러 (자세한 내용은 매뉴얼참조)
			// reply_msg 가 실패에 대한 메세지
			sb.append("결과코드		: ").append(replyCd).append(", ");
			sb.append("결과메세지	: ").append(replyMsg);
		}

		//결제취소처리
		m.log("allat_fail", "실패 결제 데이터 : " + hm + " \n취소 요청 데이터 : " + resHm + "\n결제 취소 결과 : " + sb);

		//자동취소결과 업데이트
		payment.clear();
		payment.item("cancel_code", replyCd); //취소응답코드
		payment.item("cancel_msg", replyMsg); //취소응답결과메시지
		payment.update("id = " + newPaymentId + "");

		//주문, 주문항목 결제취소 처리
		order.rollback(oid, list);

		m.jsAlert(_message.get("alert.course.noquantity")  + "\n" + _message.get("alert.payment.canceled_by_error") + "[resultMsg=>" + sReplyMsg + ", resultCode=>" + sReplyCd + "]");
		m.jsReplace(payUrl, "parent.parent");
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
		p.setVar("limit_date_conv", Malgn.time("yyyy.MM.dd", sIncomeLimitYmd));
		p.setVar("payment", payment.find("id = " + newPaymentId + " AND oid = " + oid));
		mail.send(siteinfo, uinfo, "account", p);
		if("Y".equals(siteconfig.s("ktalk_yn"))) {
			p.setVar("user_nm", info.s("ord_nm"));
			p.setVar("order_nm", info.s("order_nm"));
			p.setVar("saowner", sBankAccountNm);
			p.setVar("pay_account", financeName + "은행 " + sAccountNo);
			p.setVar("pay_price_conv", info.s("pay_price_conv"));
			ktalkTemplate.sendKtalk(siteinfo, uinfo, "account", p);
		} else {
			smsTemplate.sendSms(siteinfo, uinfo, "account", p);
		}
	} else {
		mail.send(siteinfo, uinfo, "payment", p);
		if("Y".equals(siteconfig.s("ktalk_yn"))) {
			p.setVar("ord_nm", info.s("ord_nm"));
			p.setVar("order_nm", info.s("order_nm"));
			p.setVar("pay_price_conv", info.s("pay_price_conv"));
			p.setVar("paymethod_conv", info.s("paymethod_conv"));
			ktalkTemplate.sendKtalk(siteinfo, uinfo, "payment", p, "P");
		} else {
			smsTemplate.sendSms(siteinfo, uinfo, "payment", p, "P");
		}
	}

	//정상처리시 결과페이지로
	String eKey = m.encrypt(oid + userId + "__LMS2014");
	m.jsReplace("payment_complete.jsp?ek=" + eKey + "&oid=" + m.encode(""+oid), "parent");
	return;

} else {
	m.jsAlert(_message.get("alert.payment.result_message", new String[] {"resultMsg=>" + sReplyMsg, "resultCode=>" + sReplyCd}));
}

%>