<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String ek = m.rs("ek");
int iid = m.ri("iid");
if("".equals(ek) || iid == 0) { m.jsErrClose(_message.get("alert.common.required_key")); return; }

//암호키
if(!ek.equals(m.encrypt("" + iid + userId))) { m.jsErrClose(_message.get("alert.common.abnormal_access")); return; }

//객체
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

FreepassDao freepass = new FreepassDao();
FreepassUserDao freepassUser = new FreepassUserDao(siteId);

CourseDao course = new CourseDao();
OrderItemDao orderItem = new OrderItemDao(siteId);
BookDao book = new BookDao();

//변수
String today = m.time("yyyyMMdd");
boolean cartBlock = 0 > iid;

//정보
DataSet info = new DataSet();
if(!cartBlock) {
	info = orderItem.query(
		"SELECT a.*"
		+ ", c.id course_id, c.category_id course_category_id, c.course_type, c.course_nm, b.book_nm "
		+ ", b.book_price, c.price c_price "
		+ ", IFNULL(c.course_nm, b.book_nm) product_nm, IFNULL (c.price, b.book_price) product_price "
		+ " FROM " + orderItem.table + " a "
		+ " LEFT JOIN " + course.table + " c ON a.product_type = 'course' AND a.product_id = c.id "
		+ " LEFT JOIN " + book.table + " b ON a.product_type = 'book' AND a.product_id = b.id "
		+ " WHERE a.id = " + iid + " "
		//+ " AND a.user_id = " + userId + " AND a.order_id = -99 AND a.status = 20 "
		+ " AND a.user_id = " + userId + " AND a.status IN (-99, 20) "
		+ " ORDER BY a.id ASC "
	);
} else {
	
}
if(!info.next()) { m.jsErrClose(_message.get("alert.common.nodata")); return; }
info.put("product_nm_conv", m.cutString(info.s("product_nm"), 200));
info.put("product_price_conv", m.nf(info.i("product_price")));
info.put("price_conv", m.nf(info.i("price")));

//삭제-기존적용된쿠폰
if(!orderItem.cancelDiscount(iid, info.i("coupon_user_id"))) {
	m.jsAlert(_message.get("alert.common.error_init"));
	m.js("parent.location.href = parent.location.href");
	return;
}

//처리
if("apply_coupon".equals(m.rs("mode"))) {
	//기본키
	int did = m.ri("did");
	if(did == 0) { m.jsAlert(_message.get("alert.common.required_key")); return; }

	//삭제-기존적용할인
	if(!orderItem.cancelDiscount(iid, info.i("coupon_user_id"))) {
		m.jsAlert(_message.get("alert.common.error_init"));
		m.js("parent.location.href = parent.location.href");
		return;
	}

	//정보-쿠폰
	DataSet cinfo = couponUser.query(
		"SELECT b.*, a.use_date, c.course_nm "
		+ " FROM " + couponUser.table + " a "
		+ " INNER JOIN " + coupon.table + " b ON b.id = a.coupon_id AND b.site_id = " + siteId + " AND b.status = 1 "
		+ " LEFT JOIN " + course.table + " c ON b.course_id = c.id "
		+ " WHERE a.id = " + did + " AND a.user_id = " + userId + " AND a.use_yn = 'N' "
		+ " AND b.start_date <= '" + today + "' AND b.end_date >= '" + today + "' "
	);
	if(!cinfo.next()) { m.jsAlert(_message.get("alert.coupon.nodata")); return; }

	//제한-적용여부
	if(!couponUser.isValid(cinfo, info)) { m.jsAlert(_message.get("alert.coupon.not_applicable")); return; }

	//계산-할인금액
	int dcPrice = couponUser.getDiscountPrice(cinfo, info);
	if(!orderItem.applyCoupon(iid, dcPrice, did)) { m.jsAlert(_message.get("alert.payment.error_apply")); return; }

	//이동
	m.js("try { parent.parent.location.href = parent.parent.location.href } catch(e) { alert('결제창이 이동되었습니다. 현재 창은 닫힙니다.'); }");
	return;
} else if("apply_freepass".equals(m.rs("mode"))) {
	//기본키
	int did = m.ri("did");
	if(did == 0) { m.jsAlert(_message.get("alert.common.required_key")); return; }

	//삭제-기존적용할인
	if(!orderItem.cancelDiscount(iid, info.i("coupon_user_id"))) {
		m.jsAlert(_message.get("alert.common.error_init"));
		m.js("parent.location.href = parent.location.href");
		return;
	}

	//정보-프리패스
	DataSet finfo = freepassUser.query(
		"SELECT f.*, a.freepass_id, a.user_id, a.start_date, a.end_date, a.limit_cnt "
		+ " FROM " + freepassUser.table + " a "
		+ " INNER JOIN " + freepass.table + " f ON f.id = a.freepass_id AND f.site_id = " + siteId + " AND f.status = 1 "
		+ " WHERE a.id = " + did + " AND a.user_id = " + userId + " AND (a.limit_cnt = 0 OR a.use_cnt < a.limit_cnt) "
		+ " AND a.start_date <= '" + today + "' AND a.end_date >= '" + today + "' "
	);
	if(!finfo.next()) { m.jsAlert(_message.get("alert.freepass.nodata")); return; }

	//제한-적용여부
	if(!freepassUser.isValid(finfo, info)) { m.jsAlert(_message.get("alert.freepass.not_applicable")); return; }

	//제한-수량
	//if() { }

	//계산-할인금액
	if(!orderItem.applyFreepass(iid, info.i("price"), did)) { m.jsAlert(_message.get("alert.payment.error_apply")); return; }

	//이동
	m.js("try { parent.parent.location.href = parent.parent.location.href } catch(e) { alert('결제창이 이동되었습니다. 현재 창은 닫힙니다.'); }");
	return;
} else if("price_coupon".equals(m.rs("mode"))) {
	//기본키
	int cid = m.ri("cid");
	if(cid == 0) { out.print("-1"); return; }

	//정보-쿠폰
	DataSet cinfo = couponUser.query(
		"SELECT b.*, a.use_date, c.course_nm "
		+ " FROM " + couponUser.table + " a "
		+ " INNER JOIN " + coupon.table + " b ON b.id = a.coupon_id AND b.site_id = " + siteId + " AND b.status = 1 "
		+ " LEFT JOIN " + course.table + " c ON b.course_id = c.id "
		+ " WHERE a.id = " + cid + " AND a.user_id = " + userId + " AND a.use_yn = 'N' "
		+ " AND b.start_date <= '" + today + "' AND b.end_date >= '" + today + "' "
	);
	if(!cinfo.next()) { out.print("-1"); return; }

	//출력
	out.print("" + couponUser.getDiscountPrice(cinfo, info));
	return;
}


//폼체크
f.addElement("coupon_no", null, "hname:'쿠폰번호', required:'Y', maxbyte:'50', pattern:'^[a-zA-Z0-9]{1,50}$', errmsg:'영숫자로 입력하세요.'");

//등록
if(m.isPost() && f.validate()) {

	String couponNo = f.get("coupon_no").toUpperCase();

	//정보-쿠폰
	DataSet cinfo = couponUser.query(
		"SELECT a.*, b.public_yn, b.start_date, b.end_date, b.status "
		+ " FROM " + couponUser.table + " a "
		+ " INNER JOIN " + coupon.table + " b ON a.coupon_id = b.id AND b.status = 1 AND b.site_id = " + siteId + " "
		+ " WHERE a.coupon_no = '" + couponNo + "' AND a.user_id IN (-99, 0, " + userId + ") "
		+ " ORDER BY a.user_id DESC "
		, 1
	);
	if(!cinfo.next()) { m.jsAlert(_message.get("alert.coupon.unvalid_no")); return; }

	//제한
	if(0 > m.diffDate("D", today, cinfo.s("end_date"))) { m.jsAlert(_message.get("alert.coupon.expired")); return;	}

	//보유여부
	if(cinfo.i("user_id") > 0 && cinfo.b("use_yn")) { m.jsAlert(_message.get("alert.coupon.used")); return; }
	else if(cinfo.i("user_id") > 0 && !cinfo.b("use_yn")) { m.jsAlert(_message.get("alert.coupon.owned")); return; }


	if(cinfo.b("public_yn")) {
		couponUser.item("site_id", siteId);
		couponUser.item("coupon_no", couponNo);
		couponUser.item("coupon_id", cinfo.i("coupon_id"));
		couponUser.item("user_id", userId);
		couponUser.item("use_yn", "N");
		couponUser.item("use_date", "");
		couponUser.item("reg_date", m.time("yyyyMMddHHmmss"));
		if(!couponUser.insert()) { m.jsAlert(_message.get("alert.coupon.error_insert")); return; }
	} else {
		couponUser.item("user_id", userId);
		couponUser.item("reg_date", m.time("yyyyMMddHHmmss"));
		if(!couponUser.update("id = " + cinfo.i("id") + "")) { m.jsAlert(_message.get("alert.coupon.error_insert")); return; }
	}

	m.jsAlert(_message.get("alert.coupon.success_insert"));
	m.jsReplace("discount_apply.jsp?" + m.qs(), "parent");
	return;
}


//목록
DataSet clist = couponUser.query(
	"SELECT b.*, a.id cpid, a.use_date, c.course_nm "
	+ " FROM " + couponUser.table + " a "
	+ " INNER JOIN " + coupon.table + " b ON b.id = a.coupon_id AND b.site_id = " + siteId + " AND b.status = 1 "
	+ " LEFT JOIN " + course.table + " c ON b.course_id = c.id "
	+ " WHERE a.user_id = " + userId + " AND a.use_yn = 'N' "
	+ " AND  b.start_date <= '" + today + "' AND b.end_date >= '" + today + "' "
	+ " ORDER BY a.reg_date DESC "
);
while(clist.next()) {
	clist.put("coupon_type_conv", m.getValue(clist.s("coupon_type"), coupon.couponTypesMsg));
	clist.put("disc_value_conv", "P".equals(clist.s("disc_type")) ? siteinfo.s("currency_prefix") + m.nf(clist.i("disc_value")) + siteinfo.s("currency_suffix") : clist.i("disc_value") + "%");
	clist.put("min_price_block", clist.i("min_price") > 0);
	clist.put("min_price_conv", m.nf(clist.i("min_price")));
	clist.put("limit_price_block", "R".equals(clist.s("disc_type")) && clist.i("limit_price") > 0);
	clist.put("limit_price_conv", m.nf(clist.i("limit_price")));
	clist.put("start_date_conv", m.time(_message.get("format.date.dot"), clist.s("start_date")));
	clist.put("end_date_conv", m.time(_message.get("format.date.dot"), clist.s("end_date")));

	boolean isValid = couponUser.isValid(clist, info);
	int dcPrice = isValid ? couponUser.getDiscountPrice(clist, info) : 0;

	clist.put("apply_block", isValid);
	clist.put("apply_class", isValid ? "valid" : "invalid");
	clist.put("dc_price", dcPrice);
	clist.put("dc_price_conv", m.nf(dcPrice));
}
clist.sort("apply_block", "DESC");

//목록-프리패스
//freepassUser.d(out);
DataSet flist = !"course".equals(info.s("product_type")) ? new DataSet() : freepassUser.query(
	"SELECT a.*, a.id fpid, f.freepass_nm "
	+ " FROM " + freepassUser.table + " a "
	+ " INNER JOIN " + freepass.table + " f ON a.freepass_id = f.id and f.status = 1"
	+ " WHERE a.user_id = " + userId + " AND a.status = 1 "
	+ " AND a.start_date <= '" + today + "' AND a.end_date >= '" + today + "' AND (a.limit_cnt = 0 OR a.use_cnt < a.limit_cnt) "
	+ " ORDER BY a.end_date DESC, a.id DESC "
);
while(flist.next()) {
	flist.put("start_date_conv", m.time(_message.get("format.date.dot"), flist.s("start_date")));
	flist.put("end_date_conv", m.time(_message.get("format.date.dot"), flist.s("end_date")));
	flist.put("use_cnt_conv", m.nf(flist.i("use_cnt")));
	flist.put("limit_cnt_conv", (flist.i("limit_cnt") > 0 ? m.nf(flist.i("limit_cnt")) + _message.get("list.freepass_user.etc.limited") : _message.get("list.freepass_user.etc.unlimited")));
	flist.put("apply_block", flist.b("is_valid"));
	flist.put("apply_class", flist.b("is_valid") ? "valid" : "invalid");

	boolean isValid = freepassUser.isValid(flist, info);

	flist.put("apply_block", isValid);
	flist.put("apply_class", isValid ? "valid" : "invalid");
}
flist.sort("apply_block", "DESC");

//출력
p.setLayout("blank");
p.setBody("mypage.discount_apply");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());

p.setVar(info);
p.setLoop("clist", clist);
p.setLoop("flist", flist);
p.setVar("no_block", 1 > clist.size() && 1 > flist.size());

p.display();

%>