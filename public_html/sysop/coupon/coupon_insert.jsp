<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(104, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();
CourseDao course = new CourseDao();

//폼체크
f.addElement("coupon_nm", null, "hname:'쿠폰명', required:'Y'");
f.addElement("coupon_type", "A", "hname:'쿠폰범위', required:'Y'");
f.addElement("min_price", 0, "hname:'최소금액', required:'Y', option:'number'");
f.addElement("disc_type", "P", "hname:'할인구분', required:'Y'");
f.addElement("disc_value", 0, "hname:'할인가', required:'Y', option:'number'");
f.addElement("limit_price", 0, "hname:'최대금액', required:'Y', option:'number'");
f.addElement("start_date", null, "hname:'시작일', required:'Y'");
f.addElement("end_date", null, "hname:'종료일', required:'Y'");
f.addElement("coupon_cnt", 0, "hname:'발행수', option:'number', required:'Y', max:'5000'");
f.addElement("course_nm", null, "hname:'과정명'");
f.addElement("public_yn", "N", "hname:'공용여부', required:'Y'");
f.addElement("status", 0, "hname:'상태', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	if(f.getInt("disc_value") <= 0) { m.jsAlert("할인가는 1이상이어야 합니다."); return; }
	if("R".equals(f.get("disc_type")) && f.getInt("disc_value") > 100) { m.jsAlert("할인가는 100%이하이어야 합니다."); return; }

	int newId = coupon.getSequence();

	coupon.item("id", newId);
	coupon.item("site_id", siteId);
	coupon.item("coupon_nm", f.get("coupon_nm"));
	coupon.item("coupon_type", f.get("coupon_type"));
	coupon.item("disc_type", f.get("disc_type"));
	coupon.item("disc_value", f.get("disc_value"));
	coupon.item("min_price", f.get("min_price"));
	coupon.item("limit_price", f.get("limit_price"));
	coupon.item("start_date", m.time("yyyyMMdd", f.get("start_date")));
	coupon.item("end_date", m.time("yyyyMMdd", f.get("end_date")));
	coupon.item("course_id", f.getInt("course_id"));
	coupon.item("public_yn", f.get("public_yn"));

	if("Y".equals(f.get("public_yn"))) {
		coupon.item("coupon_cnt", 0);
	}
	else {
		if(f.getInt("coupon_cnt") <= 0) { m.jsAlert("개별 쿠폰은 1장 이상 발행해야 합니다."); return; }
		else if(f.getInt("coupon_cnt") > 5000) { m.jsAlert("쿠폰은 한 번에 5000장까지 발행할 수 있습니다."); return; }

		coupon.item("coupon_cnt", f.getInt("coupon_cnt"));
	}
	coupon.item("reg_date", m.time("yyyyMMddHHmmss"));
	coupon.item("status", f.getInt("status"));

	if(!coupon.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	if("N".equals(f.get("public_yn"))) {
		if(f.getInt("coupon_cnt") > 0) {
			int failCnt = 0;
			for(int i=1; i<=f.getInt("coupon_cnt"); i++) {
				couponUser.item("site_id", siteId);
				couponUser.item("coupon_no", coupon.getCouponNo());
				couponUser.item("coupon_id", newId);
				couponUser.item("user_id", 0);
				couponUser.item("use_yn", "N");
				couponUser.item("use_date", "");
				couponUser.item("reg_date", "");

				if(!couponUser.insert()) {
					couponUser.item("coupon_no", coupon.getCouponNo());
					if(!couponUser.insert()) { failCnt++; }
				}
			}
			if(failCnt > 0) m.jsAlert("쿠폰 발행을 " + failCnt + "건 실패하였습니다.");

			coupon.updateCouponCnt(newId);
		}
	} else {
		String couponNo = coupon.getCouponNo();
		if(couponUser.findCount("coupon_no = '" + couponNo + "'") > 0) couponNo = coupon.getCouponNo();
		couponUser.item("site_id", siteId);
		couponUser.item("coupon_no", couponNo);
		couponUser.item("coupon_id", newId);
		couponUser.item("user_id", -99);
		couponUser.item("use_yn", "N");
		couponUser.item("use_date", "");
		couponUser.item("reg_Date", "");
		if(!couponUser.insert()) {}
	}

	m.jsReplace("coupon_list.jsp?" + m.qs(), "parent");
	return;
}

//출력
p.setBody("coupon.coupon_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("coupon_types", m.arr2loop(coupon.couponTypes));
p.setLoop("disc_types", m.arr2loop(coupon.discTypes));
p.setLoop("public_types", m.arr2loop(coupon.publicTypes));
p.setLoop("status_list", m.arr2loop(coupon.statusList));

p.display();

%>
