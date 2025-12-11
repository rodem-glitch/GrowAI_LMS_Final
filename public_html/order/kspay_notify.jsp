<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

String cmid = siteinfo.s("pg_id");
String mkey = siteinfo.s("pg_key");

//결제정보
DataSet pinfo = new DataSet(); pinfo.addRow();
pinfo.put("code", m.rs("LGD_RESPCODE").trim());
pinfo.put("msg", m.rs("LGD_RESPMSG").trim());
pinfo.put("cmid", cmid);
pinfo.put("mkey", mkey);
pinfo.put("mid", m.rs("LGD_MID").trim());
pinfo.put("oid", m.rs("LGD_OID").trim());
pinfo.put("tid", m.rs("LGD_TID").trim());
pinfo.put("pay_price", m.rs("LGD_AMOUNT").trim());
pinfo.put("paymethod", m.rs("LGD_PAYTYPE").trim());
pinfo.put("pay_date", m.rs("LGD_PAYDATE").trim());
pinfo.put("hashdata", m.rs("LGD_HASHDATA").trim());
pinfo.put("financecode", m.rs("LGD_FINANCECODE").trim());
pinfo.put("financename", m.rs("LGD_FINANCENAME").trim());
pinfo.put("escrowyn", m.rs("LGD_ESCROWYN").trim());
pinfo.put("timestamp", m.rs("LGD_TIMESTAMP").trim());
pinfo.put("accountnum", m.rs("LGD_ACCOUNTNUM").trim());
pinfo.put("castamount", m.rs("LGD_CASTAMOUNT").trim());
pinfo.put("cascamount", m.rs("LGD_CASCAMOUNT").trim());
pinfo.put("casflag", m.rs("LGD_CASFLAG").trim());
pinfo.put("casseqno", m.rs("LGD_CASSEQNO").trim());
pinfo.put("cashreceiptnum", m.rs("LGD_CASHRECEIPTNUM").trim());
pinfo.put("cashreceiptselfyn", m.rs("LGD_CASHRECEIPTSELFYN").trim());
pinfo.put("cashreceiptkind", m.rs("LGD_CASHRECEIPTKIND").trim());
pinfo.put("payer", m.rs("LGD_PAYER").trim());

pinfo.put("buyer", m.rs("LGD_BUYER").trim());
pinfo.put("productinfo", m.rs("LGD_PRODUCTINFO").trim());
pinfo.put("buyerid", m.rs("LGD_BUYERID").trim());
pinfo.put("buyeraddress", m.rs("LGD_BUYERADDRESS").trim());
pinfo.put("buyerphone", m.rs("LGD_BUYERPHONE").trim());
pinfo.put("buyeremail", m.rs("LGD_BUYEREMAIL").trim());
pinfo.put("buyerssn", m.rs("LGD_BUYERSSN").trim());
pinfo.put("productcode", m.rs("LGD_PRODUCTCODE").trim());
pinfo.put("receiver", m.rs("LGD_RECEIVER").trim());
pinfo.put("receiverphone", m.rs("LGD_RECEIVERPHONE").trim());
pinfo.put("deliveryinfo", m.rs("LGD_DELIVERYINFO").trim());

pinfo.put("hashdata2", m.encrypt(pinfo.s("mid") + pinfo.s("oid") + pinfo.s("pay_price") + pinfo.s("code") + pinfo.s("timestamp") + pinfo.s("mkey")));

/* ********************************************* 테스트 URL ***********************************************
 * 디버깅  http://lms.malgn.co.kr/main/cas_noteurl.jsp?LGD_RESPCODE=0000&LGD_CASFLAG=I&LGD_OID=[order_id] *
 * 테스트  https://pgweb.uplus.co.kr:8443/pg/wmp/Home2009/demo/xpaydemo/httpCasDeposit.jsp                *
 ******************************************************************************************************** */

String msg = "결제결과 상점 DB처리(LGD_CASNOTEURL) 결과값을 입력해 주시기 바랍니다.";
if(pinfo.s("hashdata2").equals(pinfo.s("hashdata")) || -1 < request.getServerName().indexOf("lms.malgn.co.kr")) { //해쉬값 검증이 성공이면 또는 개발서버이면
	if("0000".equals(pinfo.s("code"))) { //결제가 성공이면
		if("R".equals(pinfo.s("casflag"))) {
			msg = "OK";

		} else if("I".equals(pinfo.s("casflag"))) { //무통장 입금 성공 결과 상점 처리(DB) 부분
			OrderDao order = new OrderDao();
			order.setMessage(_message);
			if(order.confirmDeposit(pinfo.s("oid"), siteinfo, pinfo)) msg = "OK";
			else msg = "결제완료 처리하는 중 오류가 발생하였습니다.";

		} else if("C".equals(pinfo.s("casflag"))) { //무통장 입금취소 성공 결과 상점 처리(DB) 부분
			msg = "OK";

		}
	} else { //결제가 실패이면
		msg = "OK";

	}
} else {
	msg = "결제결과 상점 DB처리(LGD_CASNOTEURL) 해쉬값 검증이 실패하였습니다.";
}

String str = "[TYPE:" + pinfo.s("casflag")
	+ " OID:" + pinfo.s("oid")
	+ ", TID:" + pinfo.s("tid")
	+ ", CODE:" + pinfo.s("code")
	+ ", MSG:" + pinfo.s("msg")
	+ ", BUYER:" + pinfo.s("buyer")
	+ ", BUYERID:" + pinfo.s("buyerid")
	+ ", PRODUCT:" + pinfo.s("productinfo")
	+ "]";
m.log("casnoteurl", str + "\n - " + msg);

out.println(msg);

%>