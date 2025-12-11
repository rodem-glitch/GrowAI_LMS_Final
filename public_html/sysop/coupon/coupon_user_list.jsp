<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(104, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
int cuid = m.ri("cuid");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();
UserDao user = new UserDao(isBlindUser);

//정보
DataSet info = coupon.query(
	"SELECT a.*, b.coupon_no, b.use_yn, c.course_nm "
	+ " FROM " + coupon.table + " a "
	+ (cuid == 0
		? " LEFT JOIN " + couponUser.table + " b ON a.id = b.coupon_id AND b.user_id = -99 "
		: " LEFT JOIN " + couponUser.table + " b ON a.id = b.coupon_id AND b.id = " + cuid
	)
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id AND c.status != -1 "
	+ " WHERE a.id = " + id + " AND a.status > -1"
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//info.put("coupon_no_conv", coupon.addHyphen(info.s("coupon_no")));
info.put("coupon_type_conv", m.getItem(info.s("coupon_type"), coupon.couponTypes));
info.put("disc_type_conv", m.getItem(info.s("disc_type"), coupon.discTypes));
info.put("disc_value_conv", "P".equals(info.s("disc_type")) ? m.nf(info.i("disc_value")) + "원" : info.i("disc_value") + "%" + ((info.i("limit_price") > 0) ? " (최대 " + m.nf(info.i("limit_price")) + "원)" : ""));
info.put("min_price_block", 0 < info.i("min_price"));
info.put("min_price_conv", m.nf(info.i("min_price")));
info.put("start_date_conv", !"".equals(info.s("start_date")) ? m.time("yyyy-MM-dd", info.s("start_date")) : "");
info.put("end_date_conv", !"".equals(info.s("end_date")) ? m.time("yyyy-MM-dd", info.s("end_date")) : "");
info.put("status_conv", m.getItem(info.s("status"), coupon.statusList));
info.put("public_yn_conv", m.getItem(info.s("public_yn"), coupon.publicTypes));
info.put("course_block", 0 < info.i("course_id"));

//폼체크
f.addElement("s_use_yn", null, null);
f.addElement("s_user_field", null, null);
f.addElement("s_user_keyword", null, null);

if("Add".equals(m.rs("mode"))) {
	if(m.ri("cno") <= 0) { m.jsAlert("쿠폰은 1장 이상 발행해야 합니다."); return; }
	else if(m.ri("cno") > 5000) { m.jsAlert("쿠폰은 한 번에 5000장까지 발행할 수 있습니다."); return; }

	int failCnt = 0;
	int successCnt = 0;
	for(int i=1; i<=m.ri("cno"); i++) {
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

	m.jsAlert(successCnt + "장의 쿠폰을 추가 발행했습니다.");

	m.jsReplace("coupon_user_list.jsp?" + m.qs("mode, cno"), "parent");
	return;
} else if("Return".equals(m.rs("mode"))) {
	//제한
	if(info.b("use_yn")) { m.jsAlert("이미 사용한 쿠폰입니다."); return; }

	//회수
	couponUser.item("user_id", 0);
	couponUser.item("use_yn", "N");
	couponUser.item("use_date", "");
	couponUser.item("reg_date", "");
	if(!couponUser.update("id = " + cuid)) { m.jsAlert("쿠폰을 회수하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("coupon_user_list.jsp?" + m.qs("mode, cuid"), "parent");
	return;
}

//폼체크
Form f3 = new Form("form3");
f3.setRequest(request);
f3.addElement("coupon_nm", info.s("coupon_nm"), "hname:'쿠폰명', required:'Y'");
f3.addElement("status", info.i("status"), "hname:'상태', required:'Y', option:'number'");
f3.addElement("start_date", info.s("start_date_conv"), "hname:'시작일', required:'Y'");
f3.addElement("end_date", info.s("end_date_conv"), "hname:'종료일', required:'Y'");

//수정
if(m.isPost() && f3.validate()) {
	coupon.item("coupon_nm", f3.get("coupon_nm"));
	coupon.item("status", f3.get("status"));
	coupon.item("start_date", m.time("yyyyMMdd", f3.get("start_date")));
	coupon.item("end_date", m.time("yyyyMMdd", f3.get("end_date")));

	if(!coupon.update("id = " + info.i("id"))) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.jsAlert("수정했습니다.");
	m.jsReplace("coupon_user_list.jsp?" + m.qs(), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setTable(
	couponUser.table + " a "
	+ " INNER JOIN " + coupon.table + " b ON a.coupon_id = b.id AND b.status > -1 AND b.site_id = " + siteId
	+ " LEFT JOIN " + user.table + " c ON a.user_id = c.id "
);
lm.setFields("a.*, c.id user_id, c.user_nm, c.login_id");
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.addWhere("a.user_id != -99");
lm.addWhere("a.coupon_id = " + id);
lm.addSearch("a.use_yn", m.rs("s_use_yn"));
if(!"".equals(m.rs("s_user_field"))) lm.addSearch(m.rs("s_user_field"), m.rs("s_user_keyword"), "LIKE");
else lm.addSearch("a.coupon_no, c.login_id, c.user_nm", m.rs("s_user_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	//list.put("coupon_no_conv", coupon.addHyphen(list.s("coupon_no")));
	list.put("use_yn_conv", m.getItem(list.s("use_yn"), couponUser.useTypes));
	list.put("use_date_conv", !"".equals(list.s("use_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("use_date")) : "-");
	list.put("reg_date_conv", !"".equals(list.s("reg_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("reg_date")) : "-");
	list.put("user_id", !"".equals(list.s("user_id")) ? list.s("user_id") : "");
	list.put("user_not_block", "".equals(list.s("user_id")) || "0".equals(list.s("user_id")));
	list.put("user_nm", !"".equals(list.s("user_nm")) ? list.s("user_nm") : "-");
	list.put("return_block", !info.b("public_yn") && !list.b("use_yn") && list.i("user_id") > 0);
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "쿠폰번호관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "coupon_no=>쿠폰번호", "login_id=>회원아이디", "user_nm=>회원명", "use_yn_conv=>사용여부", "use_date_conv=>사용일", "reg_date_conv=>쿠폰발급일" }, info.s("coupon_nm") + "(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("coupon.coupon_user_list");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("coupon_query", m.qs("id, s_user_field, s_user_keyword, s_use_yn, ord, mode, page"));
p.setVar("form_script", f.getScript());
p.setVar("form3_script", f3.getScript());

p.setVar(info);
p.setVar("list_total", lm.getTotalString());
p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.setLoop("use_list", m.arr2loop(couponUser.useTypes));
p.setLoop("status_list", m.arr2loop(coupon.statusList));
p.display();

%>