<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(104, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CouponDao coupon = new CouponDao();
CourseDao course = new CourseDao();
CouponUserDao couponUser = new CouponUserDao();

//폼체크
f.addElement("s_course_id", null, null);
f.addElement("s_coupon_type", null, null);
f.addElement("s_disc_type", null, null);
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);
f.addElement("s_public_yn", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setTable(	
	coupon.table + " a "
	+ " LEFT JOIN " + course.table + " b ON a.course_id = b.id AND b.status > -1 "
	+ " LEFT JOIN " + couponUser.table + " cu ON a.public_yn = 'Y' AND a.id = cu.coupon_id AND user_id = -99 "
);
lm.setFields("a.*, b.course_nm, cu.coupon_no, (SELECT COUNT(*) FROM " + couponUser.table + " WHERE user_id != -99 AND coupon_id = a.id) public_coupon_cnt");
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.addWhere("a.status > -1");
lm.addWhere("a.site_id = " + siteId);
lm.addSearch("a.course_id", f.get("s_course_id"));
lm.addSearch("a.coupon_type", m.rs("s_coupon_type"));
lm.addSearch("a.disc_type", m.rs("s_disc_type"));
lm.addSearch("a.start_date", m.time("yyyyMMdd", m.rs("s_edate")), "<=");
lm.addSearch("a.end_date", m.time("yyyyMMdd", m.rs("s_sdate")), ">=");
lm.addSearch("a.public_yn", m.rs("s_public_yn"));
if(!"".equals(m.rs("s_field"))) lm.addSearch(m.rs("s_field"), m.rs("s_keyword"), "LIKE");
else lm.addSearch("a.coupon_nm", m.rs("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("coupon_no_conv", !"".equals(list.s("coupon_no")) ? list.s("coupon_no") : "-");
	list.put("coupon_nm_conv", m.cutString(list.s("coupon_nm"), 60));
	list.put("coupon_type_conv", m.getItem(list.s("coupon_type"), coupon.couponTypes));
	list.put("disc_type_conv", m.getItem(list.s("disc_type"), coupon.discTypes));
	list.put("disc_value_conv", "P".equals(list.s("disc_type")) ? m.nf(list.i("disc_value")) + "원" : list.i("disc_value") + "%" + ((list.i("limit_price") > 0) ? " (" + m.nf(list.i("limit_price")) + "원)" : ""));
	list.put("min_price_block", 0 < list.i("min_price"));
	list.put("min_price_conv", m.nf(list.i("min_price")));
	list.put("start_date_conv", !"".equals(list.s("start_date")) ? m.time("yyyy.MM.dd", list.s("start_date")) : "");
	list.put("end_date_conv", !"".equals(list.s("end_date")) ? m.time("yyyy.MM.dd", list.s("end_date")) : "");
	list.put("coupon_cnt_conv", "Y".equals(list.s("public_yn")) ? m.nf(list.i("public_coupon_cnt")) : m.nf(list.i("coupon_cnt")));
	list.put("public_yn_conv", m.getItem(list.s("public_yn"), coupon.publicTypes));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), coupon.statusList));
	list.put("course_nm_conv", !"".equals(list.s("course_nm")) ? m.cutString(list.s("course_nm"), 60) : "전체");
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "쿠폰관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "coupon_no_conv=>쿠폰번호", "coupon_nm=>쿠폰명", "coupon_type_conv=>쿠폰범위", "disc_type_conv=>할인구분", "disc_value_conv=>할인혜택 ( 최대금액 )", "start_date_conv=>시작일", "end_date_conv=>종료일", "coupon_cnt_conv=>발행수", "public_yn_conv=>공용여부", "course_nm_conv=>과정명", "reg_date_conv=>등록일", "status_conv=>상태" }, "쿠폰관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("coupon.coupon_list");
p.setVar("list_query", m.qs("id, ord, page"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("list_total", lm.getTotalString());
p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.setLoop("coupon_types", m.arr2loop(coupon.couponTypes));
p.setLoop("disc_types", m.arr2loop(coupon.discTypes));
p.setLoop("public_types", m.arr2loop(coupon.publicTypes));
p.setLoop("status_list", m.arr2loop(coupon.statusList));
p.setLoop("courses", course.getCourseList(siteId, userId, userKind));

p.display();

%>
