<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { out.print("0"); return; }

//객체
OrderItemDao orderItem = new OrderItemDao();

//변수
int cartCnt = orderItem.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + orderItem.table + " a "
	//+ " WHERE a.user_id = " + userId + " AND a.order_id = -99 AND a.status IN (10, 20) "
	+ " WHERE a.user_id = " + userId + " AND a.status IN (10, 20) "
	+ " ORDER BY a.course_id ASC, a.product_type DESC, a.id ASC "
);

out.print(cartCnt);

%>