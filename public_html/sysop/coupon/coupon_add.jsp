<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(104, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

//정보
DataSet info = coupon.find("id = " + id + " AND status > -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

if("Y".equals(info.s("public_yn"))) { m.jsError("공개용 쿠폰은 추가 발행 할 수 없습니다."); return; }

//폼체크
f.addElement("coupon_cnt", 0, "hname:'추가발급수', required:'Y', option:'number'");

//추가
if(m.isPost() && f.validate()) {

	if(f.getInt("coupon_cnt") <= 0) { m.jsAlert("1장이상 입력해야 추가 발행 가능합니다."); return; }

	int failCnt = 0;
	int successCnt = 0;
	for(int i=1; i<=f.getInt("coupon_cnt"); i++) {
		couponUser.item("site_id", siteId);
		couponUser.item("coupon_no", coupon.getCouponNo());
		couponUser.item("coupon_id", info.i("id"));
		couponUser.item("user_id", 0);
		couponUser.item("use_yn", "N");
		couponUser.item("use_date", "");
		couponUser.item("reg_date", "");

		if(!couponUser.insert()) {
			couponUser.item("coupon_no", coupon.getCouponNo());
			if(!couponUser.insert()) { failCnt++; }
		}
		else successCnt++;
	}
	if(failCnt > 0) m.jsAlert("쿠폰 발행을 " + failCnt + "건 실패하였습니다.");

	coupon.updateCouponCnt(info.i("id"));

	m.jsAlert(successCnt + "장에 쿠폰을 추가 발행하였습니다.");

	m.js("parent.opener.location.href = parent.opener.location.href;");
	m.js("parent.window.close();");
	return;
}

//출력
p.setLayout("pop");
p.setBody("coupon.coupon_add");
p.setVar("p_title", "쿠폰추가발행");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.display();

%>