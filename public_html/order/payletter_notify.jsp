<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//PG에서 보냈는지 IP로 체크 
String addr = userIp.substring(0, 10);
if(!"121.254.20".equals(addr) && !"211.115.72".equals(addr)) {
	out.print("<RESULT>FAIL</RESULT>"); m.log("payletter_noti", "FAIL1-" + addr); return;
}

//폼입력
int payamt = m.ri("payamt");
int payerid = m.ri("payerid");
String payeremail = m.rs("payeremail");
String retcode = m.rs("retcode");
String retmsg = m.rs("retmsg");
String custom = m.rs("custom");
String hash = m.rs("hash");
String trantime = m.rs("trantime");
String timestamp = m.rs("timestamp");
String payinfo = m.rs("payinfo");
String pginfo = m.rs("pginfo");
String servicename = m.rs("servicename");
String currency = m.rs("currency");
String storeorderno = m.rs("storeorderno");
String cardno = m.rs("cardno");
String notifytype = m.rs("notifytype");
String paytoken = m.rs("paytoken");
String poqtoken = m.rs("poqtoken");
String cardkind = m.rs("cardkind");
String storeid = m.rs("storeid");
String countrycode = m.rs("countrycode");

//로그
m.log("payletter_noti", m.reqMap("").toString());

//제한-기본키
if(1 > payerid || "".equals(storeorderno) || "".equals(retcode) || "".equals(retmsg) || "".equals(custom) || "".equals(hash) || "".equals(notifytype)) {
	out.print("<RESULT>FAIL</RESULT>"); m.log("payletter_noti", "FAIL2_1-" + addr); return;
}

//제한-커스텀해시
String[] customArr = m.split("-", custom);
if(2 != customArr.length) {
	out.print("<RESULT>FAIL</RESULT>"); m.log("payletter_noti", "FAIL2_2-" + addr); return;
}
if(!customArr[1].equals(m.encrypt("LMS_PAYPAL_" + siteId + "_" + storeorderno + "_" + customArr[0] + "_" + payamt + payerid))) {
	out.print("<RESULT>FAIL</RESULT>"); m.log("payletter_noti", "FAIL2_3-" + addr); return;
}

//제한-페이레터해시
if(!hash.equals(m.encrypt(storeid + "USD" + storeorderno + payamt + payerid + timestamp + siteinfo.s("pg_key"), "SHA-256"))) {
	out.print("<RESULT>FAIL</RESULT>"); m.log("payletter_noti", "FAIL2_4-" + addr); return;
}

//객체
PaymentDao payment = new PaymentDao();

UserDao user = new UserDao();
MailDao mail = new MailDao();
MailTemplateDao mailTemplate = new MailTemplateDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

//제한-응답코드
if(!"0".equals(retcode) || !"1".equals(notifytype)) {
	out.print("<RESULT>FAIL</RESULT>"); m.log("payletter_noti", "FAIL3-" + addr); return;
}

//수정
payment.item("respcode", retcode);
payment.item("respmsg", retmsg);
payment.item("paykey", paytoken);
payment.item("paydate", sysNow);
payment.item("financename", cardkind);
payment.item("cardnum", cardno);
payment.item("hashdata_billkey", hash);
if(!payment.update("site_id = " + siteId + " AND tid = 'pl" + storeorderno + customArr[0] + "' AND oid = '" + storeorderno + "'")) { out.print("<RESULT>FAIL</RESULT>"); return; }

//처리-주문
OrderDao order = new OrderDao();
order.setMessage(_message);
if(order.findCount("id = " + storeorderno + " AND status = 2") > 0) {
	if(!order.confirmDeposit("" + storeorderno, siteinfo)) {
		out.print("<RESULT>FAIL</RESULT>"); m.log("payletter_noti", "FAIL5_1-" + addr); return;	
	}
} else {
	out.print("<RESULT>FAIL</RESULT>"); m.log("payletter_noti", "FAIL5_2-" + addr); return;
}

out.print("<RESULT>OK</RESULT>");

%>