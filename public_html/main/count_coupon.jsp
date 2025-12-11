<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { out.print("0"); return; }

//객체
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

//변수
String today = m.time("yyyyMMdd");

//쿠폰수
int couponCnt = couponUser.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + couponUser.table + " a "
	+ " INNER JOIN " + coupon.table + " b ON "
		+ " b.id = a.coupon_id AND b.status = 1 AND b.site_id = " + siteId + " "
	+ " WHERE a.user_id = " + userId + " "
	+ " AND a.use_yn = 'N' AND b.start_date <= '" + today + "' AND b.end_date >= '" + today + "' "
);

out.print(couponCnt);

%>