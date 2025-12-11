<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseUserDao courseUser = new CourseUserDao();
CourseDao course = new CourseDao();
OrderDao order = new OrderDao();

//기본키
int cuid = m.ri("cuid");
if(0 == cuid) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//변수
String today = m.time("yyyyMMdd");

//정보
DataSet info = courseUser.query(
	"SELECT a.*, c.course_nm, c.course_type, o.coupon_price, o.pay_price "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id "
	+ " WHERE a.id = " + cuid + " AND a.user_id = " + userId + " AND a.status IN (0, 1) "
	+ " AND a.close_yn = 'N' AND a.end_date >= '" + today + "' "
);
if(!info.next()) { m.jsAlert(_message.get("alert.common.nodata")); return; }

//제한-결제
//if(0 < info.i("order_id")) { m.jsAlert(_message.get("alert.course_user.cancel_paid")); return; }
if(0 < info.i("pay_price") || 0 < info.i("coupon_price")) { m.jsAlert(_message.get("alert.course_user.cancel_paid")); return; }

//제한-정규시작
if("R".equals(info.s("course_type")) && 0 <= m.diffDate("D", info.s("start_date"), today)) { m.jsAlert(_message.get("alert.course_user.cancel_regular")); return; }

//제한-상시수강
if("A".equals(info.s("course_type")) && info.b("complete_yn")) { m.jsAlert(_message.get("alert.course_user.cancel_completed")); return; }

//확인
if(!"Y".equals(m.rs("cnf"))) {
	out.print("<script>if(confirm('" + _message.get("confirm.common.cancel") + "')) location.href = '../mypage/course_cancel.jsp?cnf=Y&" + m.qs("cnf") + "';</script>");
	return;
}

//수강취소
courseUser.item("status", -4);
courseUser.update("id = " + cuid + " AND site_id = " + siteId + " AND user_id = " + userId);

//이동
m.jsAlert(_message.get("alert.course_user.canceled"));
m.jsReplace("../mypage/course_list.jsp", "parent");

%>