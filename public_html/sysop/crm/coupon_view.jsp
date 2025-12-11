<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();
CourseDao course = new CourseDao();
OrderItemDao orderItem = new OrderItemDao();

//변수
String today = m.time("yyyyMMdd");

//정보
DataSet info = couponUser.query(
	"SELECT b.*, a.coupon_no, a.use_yn, a.use_date, c.course_nm, oi.id order_item_id "
	+ " FROM " + couponUser.table + " a "
	+ " INNER JOIN " + coupon.table + " b ON "
		+ " b.id = a.coupon_id AND b.status > -1 AND b.site_id = " + siteId + " "
	+ " LEFT JOIN " + course.table + " c ON b.course_id = c.id "
	+ " LEFT JOIN " + orderItem.table + " oi ON oi.coupon_user_id = a.id AND oi.status IN (-99,-2,-1,10,20) "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
	+ " WHERE a.id = " + id + " AND a.user_id = " + uid + " "
);

if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//처리
if("cancel".equals(m.rs("mode"))) {
	if(1 > info.i("order_item_id")) { m.jsError("쿠폰을 해제할 수 없는 주문입니다."); return; }

	if(!orderItem.cancelDiscount(info.i("order_item_id"), id)) {
		m.jsAlert("쿠폰을 해제하는 중 오류가 발생했습니다.");
		m.jsReplace("../crm/coupon_list.jsp?" + m.qs("id,mode"));
		return;
	}

	//이동
	m.jsAlert("쿠폰해제가 완료되었습니다.");
	m.jsReplace("../crm/coupon_list.jsp?" + m.qs("id,mode"));
	return;
}

//포맷팅
info.put("coupon_type_conv", m.getItem(info.s("coupon_type"), coupon.couponTypes));
info.put("course_block", !"B".equals(info.s("coupon_type")));
info.put("course_nm_conv", !"B".equals(info.s("coupon_type")) ? (!"".equals(info.s("course_nm")) ? info.s("course_nm") : "전체과정") : "");
info.put("disc_type_conv", m.getItem(info.s("disc_type"), coupon.discTypes));
info.put("disc_value_conv", "P".equals(info.s("disc_type")) ? m.nf(info.i("disc_value")) + "원" : info.i("disc_value") + "%" + ((info.i("limit_price") > 0) ? " (" + m.nf(info.i("limit_price")) + "원)" : ""));
info.put("start_date_conv", !"".equals(info.s("start_date")) ? m.time("yyyy.MM.dd", info.s("start_date")) : "");
info.put("end_date_conv", !"".equals(info.s("end_date")) ? m.time("yyyy.MM.dd", info.s("end_date")) : "");
info.put("public_yn_conv", m.getItem(info.s("public_yn"), coupon.publicTypes));
info.put("coupon_no_conv", coupon.addHyphen(info.s("coupon_no")));
info.put("status_conv", m.getItem(info.s("status"), coupon.statusList)
);

info.put("cancel_block", 0 < info.i("order_item_id"));
info.put(
	"use_conv"
	, info.b("use_yn")
	? ((info.b("cancel_block") ? "주문중" : "사용") + " (사용일 : " + m.time("yyyy.MM.dd HH:mm", info.s("use_date")) + ")")
	: "미사용"
);

//m.p(info);
//출력
p.setLayout(ch);
p.setBody("crm.coupon_view");
p.setVar("p_title", "쿠폰상세보기");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar(info);
p.setVar("tab_coupon", "current");
p.setVar("tab_sub_coupon", "current");

p.display();

%>