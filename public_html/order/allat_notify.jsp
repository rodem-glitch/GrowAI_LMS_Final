<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//로그
m.log("allat_noti", m.reqMap("").toString());

String addr = userIp;
if(!(-1 < addr.indexOf("210.118.112") || -1 < addr.indexOf("175.158.12"))) {
	out.print("9999 올바르지 않은 접근입니다.");
	m.log("allat_noti_error", "9999 올바르지 않은 접근입니다. --- " + m.reqMap("").toString());
	return;
}

int oid = m.ri("order_no");
String tid = m.rs("tx_seq_no");

if(oid == 0 || "".equals(tid)) {
	out.print("9999 기본키는 반드시 지정해야 합니다.");
	m.log("allat_noti_error", "9999 기본키는 반드시 지정해야 합니다. --- " + m.reqMap("").toString());
	return;
}

//객체
OrderDao order = new OrderDao(); order.setMessage(_message);
OrderItemDao orderItem = new OrderItemDao();

//처리
//if(order.findCount("id = " + oid + " AND status = 2") > 0) {
DataSet info = order.find("id = " + oid + "");
if(info.next()) {
	if(info.i("status") != 2) {
		String ret = "9999 이미 처리 된 주문입니다. 현재상태 : " + info.s("status");
		String log = "9999 이미 처리 된 주문입니다. 현재상태 : " + info.s("status") + " --- " + m.reqMap("").toString();
		if(info.i("status") == 1) {
			ret = "0000 정상";
			log = "0000 정상 --- " + m.reqMap("").toString();
		}
		out.print(ret);
		m.log("allat_noti_error", log);
		return;
	}

	//금액
	if(info.i("pay_price") != m.ri("income_amt")) {
		out.print("9999 입금금액이 맞지 않습니다.");
		m.log("allat_noti_error", "9999 입금금액이 맞지 않습니다. --- " + m.reqMap("").toString());
		return;
	}
	order.confirmDeposit("" + oid, siteinfo);
	out.print("0000 정상");
} else {
	out.print("9999 해당 주문정보가 없습니다.");
	m.log("allat_noti_error", "9999 해당 주문정보가 없습니다. --- " + m.reqMap("").toString());
}

%>