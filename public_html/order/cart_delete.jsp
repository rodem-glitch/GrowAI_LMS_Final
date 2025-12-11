<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String idx = m.rs("idx");
if("".equals(idx)) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
OrderItemDao orderItem = new OrderItemDao();

//제한
if(0 < orderItem.findCount("( status != 10 OR user_id != " + userId + " ) AND id IN (" + m.join(",", idx.split("\\,")) + ")")) {
	m.jsError(_message.get("alert.order_item.permission_delete"));
	return;
}

DataSet list = orderItem.find("status = 10 AND user_id = " + userId + " AND id IN (" + m.join(",", idx.split("\\,")) + ")");
while(list.next()) {
	orderItem.deleteCartItem(list.i("id"), list.i("coupon_user_id"));
}

m.jsReplace("../order/cart_list.jsp");

%>