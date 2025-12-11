<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"ktalk_", "pay_"});

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CoursePackageDao coursePackage = new CoursePackageDao();

BookDao book = new BookDao();
BookUserDao bookUser = new BookUserDao();
BookPackageDao bookPackage = new BookPackageDao();

FreepassDao freepass = new FreepassDao();
FreepassUserDao freepassUser = new FreepassUserDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao(siteId);
PaymentDao payment = new PaymentDao();

CouponDao coupon = new CouponDao();
CouponUserDao couponUser = new CouponUserDao();

MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
KtalkDao ktalk = new KtalkDao(siteId); //ktalk.setMalgn(m);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId); //ktalkTemplate.setMalgn(m);

GroupDao group = new GroupDao();

//기본키
String eKey = m.rs("oek");
if("".equals(eKey)) {
	m.jsError("alert.common.required_key");
	return;
}

//제한
int oid = mSession.i("last_order_id");

if(!eKey.equals(order.getOrderEk(oid, userId))) {
	m.jsError("alert.order.expired");
	return;
}

//변수
DataSet methods = payment.getMethods(siteinfo);
while(methods.next()) {
	p.setVar("method_" + methods.s("id") + "_block", true);
}
methods.move(0);
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");
String yesterday = m.time("yyyyMMddHHmmss", m.addDate("D", -1, now));
String payMethod = m.rs("pay_method", methods.s("id"));
boolean isMobile = m.isMobile();
String moveDir = "/" + (!isGoMobile ? "mypage" : "mobile") + "/";

//목록-쿠폰
DataSet clist = couponUser.query(
	"SELECT b.*, a.id cpid "
	+ " FROM " + couponUser.table + " a "
	+ " INNER JOIN " + coupon.table + " b ON "
		+ " b.id = a.coupon_id AND b.status = 1 AND b.site_id = " + siteId + " "
	+ " WHERE a.user_id = " + userId + " "
	+ " AND a.use_yn = 'N' AND b.start_date <= '" + today + "' AND b.end_date >= '" + today + "' "
);
while(clist.next()) {
	clist.put("coupon_type_conv", m.getItem(clist.s("coupon_type"), coupon.couponTypes));
	clist.put("disc_value_conv", "P".equals(clist.s("disc_type")) ? m.nf(clist.i("disc_value")) + "원" : clist.i("disc_value") + "%");
	clist.put("limit_price_block", "R".equals(clist.s("disc_type")) && clist.i("limit_price") > 0);
	clist.put("limit_price_conv", m.nf(clist.i("limit_price")));
}

//처리-그룹할인률
String tmpGroups = group.getUserGroup(uinfo);
int groupDisc = group.getMaxDiscRatio();
orderItem.setGroupDisc(groupDisc);

//목록
DataSet list = orderItem.getOrderItems(userId, null, oid);
int courseNo = orderItem.courseNo;
int price = orderItem.price;
int discPrice = orderItem.discPrice;
int discGroupPrice = orderItem.discGroupPrice;
int couponPrice = orderItem.couponPrice;
int payPrice = orderItem.payPrice;
int taxfreeTarget = orderItem.taxfreeTarget;
int taxPrice = 0;
int taxTarget = 0;
boolean isDelivery = orderItem.isDelivery;
boolean memoBlock = orderItem.memoBlock;
String[] items = orderItem.items;
String productName = orderItem.productName;
DataSet courses = orderItem.courses;
DataSet ebooks = orderItem.ebooks;
DataSet freepasses = orderItem.freepasses;
DataSet useFreepasses = orderItem.useFreepasses;
DataSet escrows = orderItem.escrows;

//원격평생교육원의 경우 면세처리
/*
if("Y".equals(SiteConfig.s("taxfree_yn"))) {
	taxfreeTarget = payPrice;
	taxPrice = 0;
}
*/

//배송정보
String deliveryInfo[] = order.getDeliveryInfo(list);
String deliveryType = deliveryInfo[0];
int deliveryPrice = Integer.parseInt(deliveryInfo[1]);
int deliveryFreePrice = SiteConfig.getInt("delivery_free_price");

//배송비무료최소금액 초과시 배송비 무료
if(deliveryFreePrice > 0 && deliveryFreePrice <= payPrice) {
	deliveryType = "B";
	deliveryPrice = 0;
}

//상품명
productName = m.cutString(productName, 80);
if(list.size() >= 2) productName += " " + _message.get("payment.name.and") + " " + (list.size() - 1) + _message.get("payment.name.others");
if(deliveryPrice == 100000000) deliveryPrice = 0;
if(deliveryPrice > 0) payPrice += deliveryPrice;
boolean isFree = payPrice == 0;
boolean isCash = "90".equals(payMethod);
boolean isPg = !isFree && !isCash;
if(isFree) payMethod = "99";

//과세계산
taxPrice = (int) ((payPrice - taxfreeTarget) / 11.0);
taxTarget = payPrice - taxPrice - taxfreeTarget;

//제한-카트로이동
if(orderItem.goCart) {
	m.jsAlert(_message.get("alert.payment.canceled_by_change") + "\\n" + _message.get(orderItem.goCartMessage));
	m.jsReplace(moveDir + "cart_list.jsp");
	return;
}

//제한-쿠폰
if(!orderItem.verifyDiscount) {
	//m.redirect("../mypage/payment3.jsp?" + m.qs());
	return;
}

//제한
if(list.size() == 0) {
	m.jsAlert("alert.payment.canceled_by_empty");
	m.jsReplace(moveDir + "cart_list.jsp");
	return;
}

///결제정보
String platform = ("lgdacomxpay".equals(siteinfo.s("pg_id")) || siteinfo.b("pg_test_yn")) ? "test" : "service";
String cmid = siteinfo.s("pg_id");
String mkey = siteinfo.s("pg_key");
String monthRange = "0";
if("".equals(siteinfo.s("pg_month"))) { monthRange = "0:2:3"; }
else { for(int i = 2; i <= siteinfo.i("pg_month"); i++) monthRange += (":" + i); }
DataSet pinfo = new DataSet(); pinfo.addRow();
pinfo.put("platform", platform);
pinfo.put("cmid", cmid);
pinfo.put("mid", ("test".equals(platform) ? "t" : "") + cmid);
pinfo.put("mkey", mkey);
pinfo.put("oid", oid);
pinfo.put("datetime", now);
pinfo.put("processtype", "TWOTR");
pinfo.put("buyer", userName);
pinfo.put("buyerid", userId);
pinfo.put("phone", !"".equals(uinfo.s("mobile_conv")) ? uinfo.s("mobile_conv") : uinfo.s("phone"));
pinfo.put("ip", userIp);
pinfo.put("scheme", request.getScheme());
pinfo.put("port", "test".equals(platform) ? ("https".equals(pinfo.s("scheme")) ? ":7443" : ":7080") : "");
pinfo.put("product_nm", productName);
pinfo.put("disc_group_price", discGroupPrice);
pinfo.put("coupon_price", couponPrice);
pinfo.put("pay_price", payPrice);
pinfo.put("tax_price", taxPrice);
pinfo.put("tax_target", taxTarget);
pinfo.put("taxfree_target", taxfreeTarget);
pinfo.put("default_method", methods.s("pgid"));
pinfo.put("month_range", monthRange);
pinfo.put("protocol", siteinfo.b("ssl_yn") ? "https" : "http");
if("inicis".equals(siteinfo.s("pg_nm"))) {
	pinfo.put("mkey", m.encrypt(mkey, "SHA-256"));
	pinfo.put("hashdata", m.encrypt("oid=" + oid + "&price=" + payPrice + "&timestamp=" + now, "SHA-256"));
} else if("payletter".equals(siteinfo.s("pg_nm"))) {
	int unixtime = (int)(System.currentTimeMillis() / 1000);
	pinfo.put("unixtime", unixtime);
	pinfo.put("hashdata", m.encrypt(cmid + "USD" + oid + payPrice + userId + unixtime + mkey, "SHA-256"));
	pinfo.put("payletter_ek", unixtime + "-" + m.encrypt("LMS_PAYPAL_" + siteId + "_" + oid + "_" + unixtime + "_" + payPrice + userId));
	uinfo.put("email_conv", m.urlencode(uinfo.s("email")));
} else if("eximbay".equals(siteinfo.s("pg_nm"))) {
	pinfo.put("hashdata", m.encrypt("", "SHA-256"));
} else if("allat".equals(siteinfo.s("pg_nm"))) {
	pinfo.put("items", m.join("||", items));
} else {
	pinfo.put("hashdata", m.encrypt(pinfo.s("mid") + oid + pinfo.i("pay_price") + pinfo.s("datetime") + pinfo.s("mkey")));
}

//정보-기본정보(직전주문)
boolean worldBlock = "eximbay".equals(siteinfo.s("pg_nm"));
DataSet loinfo = order.find("site_id = " + siteId + " AND user_id = " + userId + " AND status > 0", "*", "id DESC");
if(!loinfo.next()) {
	loinfo.addRow();
	loinfo.put("ord_reci", uinfo.s("user_nm"));
	loinfo.put("zipcode", uinfo.s("zipcode"));
	loinfo.put("new_addr", uinfo.s("new_addr"));
	loinfo.put("addr_dtl", uinfo.s("addr_dtl"));
	loinfo.put("ord_mobile", uinfo.s("mobile"));

	if(worldBlock) {
		loinfo.put("bill_buyer", uinfo.s("user_nm"));
		loinfo.put("bill_zipcode", uinfo.s("zipcode"));
		loinfo.put("bill_addr1", uinfo.s("new_addr"));
		loinfo.put("bill_addr2", uinfo.s("addr_dtl"));
		loinfo.put("bill_phone", uinfo.s("mobile_conv"));
	}
}
loinfo.put("ord_mobile_conv", !"".equals(loinfo.s("ord_mobile")) ? loinfo.s("ord_mobile") : "");
String[] mobile = m.split("-", loinfo.s("ord_mobile_conv"), 3);

//폼체크
if(isDelivery) {
	f.addElement("ord_reci", loinfo.s("ord_reci"), "hname:'" + _message.get("payment.form.recipient") + "', required:'Y'");
	f.addElement("zipcode", loinfo.s("ord_zipcode"), "hname:'" + _message.get("payment.form.zipcode") + "', required:'Y'");
	f.addElement("new_addr", loinfo.s("ord_new_address"), "hname:'" + _message.get("payment.form.address1") + "', required:'Y'");
	f.addElement("addr_dtl", loinfo.s("ord_addr_dtl"), "hname:'" + _message.get("payment.form.address2") + "'");
	f.addElement("ord_mobile1", mobile[0], "hname:'" + _message.get("payment.form.mobile") + "', required:'Y', option:'number'");
	f.addElement("ord_mobile2", mobile[1], "hname:'" + _message.get("payment.form.mobile") + "', option:'number'");
	f.addElement("ord_mobile3", mobile[2], "hname:'" + _message.get("payment.form.mobile") + "', option:'number'");
	f.addElement("info_modify_yn", null, "hname:'" + _message.get("payment.form.modify_profile") + "'");
}
if(memoBlock) f.addElement("ord_memo", null, "hname:'" + _message.get("payment.form.delivery_notes") + "'");
f.addElement("pay_method", payMethod, "hname:'" + _message.get("payment.form.method") + "', required:'Y', errmsg:'" + _message.get("alert.payment.select_method") + "'");

if(worldBlock) {
	f.addElement("bill_buyer", loinfo.s("bill_buyer"), "hname:'" + _message.get("payment.form.buyer") + "', required:'Y'");
	f.addElement("bill_buyer_last", loinfo.s("bill_buyer_last"), "hname:'" + _message.get("payment.form.buyer") + "', required:'Y'");
	f.addElement("bill_country", loinfo.s("bill_country"), "hname:'" + _message.get("payment.form.country") + "', required:'Y'");
	f.addElement("bill_state", loinfo.s("bill_state"), "hname:'" + _message.get("payment.form.state") + "'");
	f.addElement("bill_zipcode", loinfo.s("bill_zipcode"), "hname:'" + _message.get("payment.form.zipcode") + "', required:'Y'");
	f.addElement("bill_addr", loinfo.s("bill_addr"), "hname:'" + _message.get("payment.form.address1") + "', required:'Y'");
	f.addElement("bill_addr_dtl", loinfo.s("bill_addr_dtl"), "hname:'" + _message.get("payment.form.address2") + "'");
	f.addElement("bill_phone", loinfo.s("bill_phone"), "hname:'" + _message.get("payment.form.mobile") + "', required:'Y', option:'number'");
	if(isDelivery) {
		f.addElement("ord_reci_last", loinfo.s("ord_reci_last"), "hname:'" + _message.get("payment.form.buyer") + "', required:'Y'");
		f.addElement("ord_country", loinfo.s("ord_country"), "hname:'" + _message.get("payment.form.country") + "', required:'Y'");
		f.addElement("ord_state", loinfo.s("ord_state"), "hname:'" + _message.get("payment.form.state") + "'");
	}
}

//결제처리
if(
	(isFree && 0 == discPrice && 0 == couponPrice && !memoBlock)
	|| (m.isPost() && f.validate())
) {

	//변수-결제항목ID
	/*
	String[] items = null;
	if(!isFree) {
		items = f.getArr("items");
	} else {
		list.first();
		ArrayList<String> numbers = new ArrayList<String>();
		while(list.next()) numbers.add(list.s("id"));
		items = numbers.toArray(new String[0]);
	}
	*/

	//결제항목점검
	if(list.size() != items.length) {
		m.jsAlert("alert.payment.canceled_by_change");
		m.jsReplace(moveDir + "cart_list.jsp", "parent");
		return;
	}
	list.first();
	while(list.next()) {
		if(!items[list.i("__ord") - 1].equals(list.s("id"))) {
			m.jsAlert("alert.payment.canceled_by_change");
			m.jsReplace(moveDir + "cart_list.jsp", "parent");
			return;
		}
	}

	//제한-수강인원제한-큰 의미는 없음 goCart와 동일
	if(orderItem.isUserLimit) {
		m.jsAlert(_message.get(orderItem.goCartMessage));
		return;
	}

	//에스크로검사
	if("Y".equals(m.rs("escrow_yn")) && (0 == escrows.size() || "01".equals(f.get("pay_method")))) {
		m.jsAlert("alert.payment.canceled_by_escrow");
		m.jsReplace(moveDir + "cart_list.jsp", "parent");
	}

	boolean isDBOK = true;
	boolean payResult = false;
	int status = -99;
	if(isCash) status = 2;
	if(isFree) status = 1;

	//주문정보등록
	order.item("site_id", siteId);
	order.item("order_date", today);
	order.item("user_id", userId);
	order.item("order_nm", productName);
	order.item("price", price);
	order.item("disc_price", discPrice);
	order.item("disc_group_price", discGroupPrice);
	order.item("coupon_price", couponPrice);
	order.item("pay_price", payPrice);
	order.item("delivery_price", deliveryPrice);
	order.item("delivery_type", deliveryType);
	order.item("paymethod", payMethod);
	order.item("refund_price", 0);
	order.item("refund_date", "");
	order.item("refund_note", "");

	order.item("ord_nm", uinfo.s("user_nm"));
	if(isDelivery) {
		order.item("ord_reci", f.get("ord_reci"));
		order.item("ord_zipcode", f.get("zipcode"));
		order.item("ord_address", "");
		order.item("ord_new_address", f.get("new_addr"));
		order.item("ord_addr_dtl", f.get("addr_dtl"));
		order.item("ord_email", uinfo.s("email"));

		String ordPhone = f.glue("-", "ord_phone1,ord_phone2,ord_phone3");
		order.item("ord_phone", !"".equals(m.replace(ordPhone, "-", "")) ? ordPhone : "");

		String ordMobile = f.glue("-", "ord_mobile1,ord_mobile2,ord_mobile3");
		order.item("ord_mobile", !"".equals(m.replace(ordMobile, "-", "")) ? ordMobile : "");

		if("Y".equals(f.get("info_modify_yn"))) {
			user.item("zipcode", f.get("zipcode"));
			user.item("addr", "");
			user.item("new_addr", f.get("new_addr"));
			user.item("addr_dtl", f.get("addr_dtl"));
			if(!siteinfo.b("auth_yn") && !siteinfo.b("ipin_yn")) {
				user.item("mobile", !"".equals(m.replace(ordMobile, "-", "")) ? ordMobile : "");
			}
			user.update("id = " + userId + " AND site_id = " + siteId);
		}
	}

	if(memoBlock) order.item("ord_memo", f.get("ord_memo"));

	if(worldBlock) {
		if(isDelivery) {
			order.item("ord_reci_last", f.get("ord_reci_last"));
			order.item("ord_country", f.get("ord_country"));
			order.item("ord_state", f.get("ord_state"));
		}
		order.item("bill_buyer", f.get("bill_buyer"));
		order.item("bill_buyer_last", f.get("bill_buyer_last"));
		order.item("bill_country", f.get("bill_country"));
		order.item("bill_zipcode", f.get("bill_zipcode"));
		order.item("bill_state", f.get("bill_state"));
		order.item("bill_addr", f.get("bill_addr"));
		order.item("bill_addr_dtl", f.get("bill_addr_dtl"));
		order.item("bill_phone", f.get("bill_phone"));
	}

	order.item("escrow_yn", f.get("escrow_yn", "N"));
	order.item("reg_date", now);
	order.item("items", m.join(",", items));
	order.item("status", status); //임시주문

	if(order.findCount("id = " + oid) == 0) {
		order.item("id", oid);
		isDBOK = order.insert();
	} else {
		isDBOK = order.update("id = " + oid);
	}

	//갱신-주문항목
	orderItem.item("order_id", oid);
	orderItem.item("status", status); //임시주문
	if(!orderItem.update("id IN (" + m.join(",", items) + ")")) {
		isDBOK = false;
	}

	if(isDBOK == false) {
		//Rollback
		list.first();
		orderItem.item("status", 10);
		while(list.next()) {
			list.put("quantity_conv", m.nf(list.i("quantity")));
			list.put("price_conv", m.nf(list.i("price")));

			orderItem.item("disc_price", 0);
			orderItem.item("price", list.i("price"));
			if(!orderItem.update("id = " + list.i("id") + "")) {}
		}
		m.jsAlert("alert.order.error_processing");
		return;
	}

	//주문처리
	if(isFree || isCash) {

		//갱신-주문항목
		orderItem.item("order_id", oid);
		orderItem.item("status", (!isFree && isCash) ? 2 : 1); // 무통장입금은 2
		if(!orderItem.update("id IN (" + m.join(",", items) + ")")) {
			isDBOK = false;
		} else {
			//주문처리
			boolean orderProcessOk = order.process(oid);
			if(!orderProcessOk) {
				//주문, 주문항목 결제취소 처리
				order.rollback(oid, list);

				m.jsAlert(_message.get("alert.course.noquantity"));
				m.jsReplace(moveDir + "cart_list.jsp");
				return;
			}
			
			//발송
			DataSet info = order.find("id = " + oid);
			if(info.next()) {
				info.put("pay_price_conv", m.nf(info.i("pay_price")));
				info.put("order_date_conv", m.time(_message.get("format.date.local"), info.s("order_date")));
				info.put("paymethod_conv", m.getItem(info.s("paymethod"), order.methods));

				p.setVar("order", info);
				p.setLoop("order_items", list);

				if(isFree) {
					mail.send(siteinfo, uinfo, "payment", p);
					if("Y".equals(siteconfig.s("ktalk_yn"))) {
						p.setVar("ord_nm", info.s("ord_nm"));
						p.setVar("order_nm", info.s("order_nm"));
						p.setVar("pay_price_conv", info.s("pay_price_conv"));
						p.setVar("paymethod_conv", info.s("paymethod_conv"));
						ktalkTemplate.sendKtalk(siteinfo, uinfo, "payment", p, "P");
					} else {
						smsTemplate.sendSms(siteinfo, uinfo, "payment", p, "P");
					}
				} else {
					mail.send(siteinfo, uinfo, "account", p);
					if("Y".equals(siteconfig.s("ktalk_yn"))) {
						p.setVar("user_nm", info.s("ord_nm"));
						p.setVar("order_nm", info.s("order_nm"));
						p.setVar("saowner", !"".equals(pinfo.s("saowner")) ? pinfo.s("saowner") : "계좌번호 참조");
						p.setVar("pay_account", siteinfo.s("pay_account"));
						p.setVar("pay_price_conv", info.s("pay_price_conv"));
						ktalkTemplate.sendKtalk(siteinfo, uinfo, "account", p);
					} else {
						smsTemplate.sendSms(siteinfo, uinfo, "account", p);
					}
				}
			}

			//정상처리시 결과페이지로
			m.jsReplace("payment_complete.jsp?ek=" + eKey + "&oid=" + m.encode(""+oid), "parent");
			return;

		}
	} else {
		m.js("parent.pay()");
		m.jsReplace("about:blank");
		return;
	}
}

//정보
DataSet priceInfo = new DataSet();
priceInfo.addRow();
priceInfo.put("price_conv", m.nf(price));
priceInfo.put("price", price);
priceInfo.put("disc_price", discPrice);
priceInfo.put("disc_price_conv", m.nf(discPrice));
priceInfo.put("disc_group_price", discGroupPrice);
priceInfo.put("disc_group_price_conv", m.nf(discGroupPrice));
priceInfo.put("coupon_price", couponPrice);
priceInfo.put("coupon_price_conv", m.nf(couponPrice));
priceInfo.put("pay_price_conv", m.nf(payPrice));
priceInfo.put("pay_price", payPrice);
priceInfo.put("delivery_price", deliveryPrice);
priceInfo.put("delivery_type", deliveryType);
priceInfo.put("delivery_price_conv",
	"A".equals(priceInfo.s("delivery_type"))
	? "<em>" + _message.get("payment.unit.cod") + "</em>"
	: "<em>" + (priceInfo.i("delivery_price") > 0 ? m.nf(priceInfo.i("delivery_price")) + "</em>원" : "무료</em>")
);

escrows.first();
while(escrows.next()) {
	if("book".equals(escrows.s("product_type"))) {
		escrows.put("good_id", escrows.i("book_id"));
		escrows.put("good_nm", m.cutString(m.addSlashes(escrows.s("book_nm")), 120, ""));
	}
}

//장바구니쿠폰임시번호
int couponTempId = m.getRandInt(-2000000, 1990000);

//출력
p.setLayout(!isGoMobile ? ch : "mobile");
//p.setBody(!isGoMobile ? "mypage.payment" : "mobile.payment");
p.setBody("order.payment");
p.setVar("p_title", "결제");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,pay_method"));
p.setVar("form_script", f.getScript());
p.setLoop("list", list);
p.setVar("quantity", courseNo);
p.setVar("user", uinfo);
p.setVar("last_order", loinfo);
p.setVar("price", priceInfo);
p.setVar("oid", oid);
p.setVar("oek", eKey);
p.setVar("pinfo", pinfo);
p.setVar("memo_block", memoBlock);
p.setVar("delivery_block", isDelivery);
p.setVar("escrow_block", "Y".equals(siteinfo.s("pg_escrow_yn")) && 0 < escrows.size());
p.setVar("free_block", isFree);
p.setVar("disc_group_block", discGroupPrice > 0);
p.setVar("disc_block", discPrice > 0 || couponPrice > 0);
p.setVar("cash_block", isCash);
p.setVar("pg_block", isPg);
p.setVar("is_mobile", isMobile);
p.setVar("coupon_temp_id", couponTempId);
p.setVar("coupon_ek", m.encrypt("" + couponTempId + userId));
p.setVar("is_group_disc_changed", groupDisc != userGroupDisc);

p.setLoop("coupons", clist);
p.setLoop("methods", methods);
p.setLoop("escrows", escrows);

//p.setVar("PG_SCRIPT", "/Users/kyounghokim/IdeaProjects/MalgnLMS/public_html/html/order/payment_"+ siteinfo.s("pg_nm") +".html");
p.setVar("PG_SCRIPT", "/order/payment_"+ siteinfo.s("pg_nm") +".html");
p.setVar("SITE_CONFIG", siteconfig);

p.display();
%>