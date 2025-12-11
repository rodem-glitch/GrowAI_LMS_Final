<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//PG에서 보냈는지 IP로 체크 
String addr = userIp.substring(0, 10);
if(!"203.238.37".equals(addr) && !"39.115.212".equals(addr) && !"210.98.138".equals(addr) && !"183.109.71".equals(addr)) {
	out.print("ERROR:미등록된서버요청");
	return;
}

int oid = m.ri("no_oid");
String tid= m.rs("no_tid");					// 취소 요청 tid에 따라서 유동적(가맹점 수정후 고정)

if(oid == 0 || "".equals(tid)) {
	out.print("ERROR:결제정보오류");
	return;
}

m.log("inicis_noti", m.reqMap("").toString());

OrderDao order = new OrderDao();
order.setMessage(_message);
if(order.findCount("id = " + oid + " AND status = 2") > 0) {
	order.confirmDeposit("" + oid, siteinfo);
}

out.print("OK");

%>