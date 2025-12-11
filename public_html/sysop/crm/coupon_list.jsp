<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();
CourseDao course = new CourseDao();
OrderItemDao orderItem = new OrderItemDao();

//변수
String today = m.time("yyyyMMdd");

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(
	couponUser.table + " a "
	+ " INNER JOIN " + coupon.table + " b ON "
		+ " b.id = a.coupon_id AND b.status != -1 AND b.site_id = " + siteId + " "
	+ " LEFT JOIN " + course.table + " c ON b.course_id = c.id "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
);
lm.setFields("b.*, a.id coupon_user_id, a.use_yn, a.use_date, c.course_nm");
lm.addWhere("a.user_id = " + uid + "");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC, a.id DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {

	DataSet oiInfo = orderItem.query(
		" SELECT id FROM " + orderItem.table
		+ " WHERE coupon_user_id = " + list.i("coupon_user_id")  + " AND site_id = " + siteId + ""
		+ " ORDER BY id DESC", 1
	);

	if(!oiInfo.next()) { }

	list.put("course_nm_conv", !"B".equals(list.s("coupon_type")) ? (!"".equals(list.s("course_nm")) ? list.s("course_nm") : "전체과정") : "");
	list.put("course_block", !"B".equals(list.s("coupon_type")));
	list.put("coupon_nm_conv", m.cutString(list.s("coupon_nm"), 30));
	list.put("coupon_type_conv", m.getItem(list.s("coupon_type"), coupon.ucouponTypes));
	list.put("disc_value_conv", "P".equals(list.s("disc_type")) ? m.nf(list.i("disc_value")) + "원" : list.i("disc_value") + "%");
	list.put("limit_price_block", "R".equals(list.s("disc_type")) && list.i("limit_price") > 0);
	list.put("limit_price_conv", m.nf(list.i("limit_price")));

	list.put("start_date_conv", m.time("yyyy.MM.dd", list.s("start_date")));
	list.put("end_date_conv", m.time("yyyy.MM.dd", list.s("end_date")));
	list.put("status_conv", m.getItem(list.s("status"), coupon.statusList));
	list.put("cancel_block", 0 < oiInfo.i("id"));

	list.put("use_conv", list.b("use_yn") ? "사용" : "미사용");
	list.put(
		"use_conv"
		, list.b("use_yn")
		? (list.b("cancel_block") ? "주문중" : "사용")
		: "미사용"
	);
}

//출력
p.setLayout(ch);
p.setBody("crm.coupon_list");
p.setVar("query", m.qs());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar("tab_coupon", "current");
p.setVar("tab_sub_coupon", "current");
p.display();

%>