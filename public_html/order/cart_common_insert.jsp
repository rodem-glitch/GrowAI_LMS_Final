<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//상품유형-상품ID[-수량]
//사용예시 : cart_common_insert.jsp?type=C&item=course,170,1|book,23,3|c_renew,1091

//cart_insert.jsp?id=123&idx=1,2,4,6,12

//로그인
if(userId == 0) {
	m.jsAlert(_message.get("alert.member.required_login"));
	m.jsReplace(auth.loginURL + "?returl=" + Malgn.urlencode(m.getThisURI()), "parent");
	return;
}

//기본키
String type = m.rs("type");
String item = m.rs("item");
if("".equals(type) || "".equals(item)) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//변수
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CoursePrecedeDao coursePrecede = new CoursePrecedeDao();
BookDao book = new BookDao();
FreepassDao freepass = new FreepassDao();
FreepassUserDao freepassUser = new FreepassUserDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

GroupDao group = new GroupDao();

//변수-목록
DataSet temp = new DataSet();
DataSet items = new DataSet();

//항목분리
String[] itemsArr = m.split("|", item);
for(int i = 0; i < itemsArr.length; i++) {
	if(-1 < itemsArr[i].indexOf(",")) {
		String[] itemDetail = m.split(",", itemsArr[i]);

		temp.addRow();
		temp.put("product_type", itemDetail[0].toLowerCase());
		temp.put("product_id", itemDetail[1]);
		temp.put("quantity", itemDetail.length > 2 ? itemDetail[2] : "1");
	}
}
temp.first();
while(temp.next()) {
	if(temp.i("quantity") <= 0) temp.put("quantity", 1);
	if(("course".equals(temp.s("product_type")) || "class".equals(temp.s("product_type"))) && temp.i("quantity") > 1) temp.put("quantity", 1);
}

//항목검사
String failed = "";
temp.first();
while(temp.next()) {
	boolean isValid = true;
	if("course".equals(temp.s("product_type"))) {
		//과정
		DataSet cinfo = course.query(
			" SELECT a.*, (CASE WHEN a.course_type = 'A' THEN 'Y' WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' ELSE 'N' END) is_request "
			+ " FROM " + course.table + " a "
			+ " WHERE id = ? AND sale_yn = 'Y' AND status = 1 AND site_id = " + siteId
			, new Integer[] { temp.i("product_id") }
		);
		if(!cinfo.next()) { failed += "\\n" + _message.get("alert.course.nodata"); isValid = false; }

		//제한-신청기간검사
		if(!"Y".equals(cinfo.s("is_request"))) { failed += "\\n[" + cinfo.s("course_nm") + "] " + _message.get("alert.course.noperiod"); isValid = false; }

		//제한-선행과정여부
		DataSet pcinfo = coursePrecede.query(
			" SELECT c.* FROM " + coursePrecede.table + " a "
			+ " INNER JOIN " + course.table + " c ON a.precede_id = c.id "
			+ " LEFT JOIN " + courseUser.table + " cu ON cu.status IN (1,3) AND cu.user_id = " + userId + " AND cu.course_id = c.id AND cu.complete_yn = 'Y' "
			+ " WHERE a.course_id = ? AND cu.complete_yn IS NULL "
			, new Integer[] { temp.i("product_id") }
			, 1
		);
		if(pcinfo.next()) { failed += "\\n[" + cinfo.s("course_nm") + "] " + _message.get("alert.course.precede_prefix") + pcinfo.s("course_nm") + _message.get("alert.course.precede_suffix"); isValid = false; }

		//제한-최대수강수검사
		if("Y".equals(cinfo.s("limit_people_yn"))
			&& cinfo.i("limit_people") <= courseUser.findCount("course_id = ? AND status NOT IN (-1, -4)", new Integer[] { temp.i("product_id") })
		) { failed += "\\n[" + cinfo.s("course_nm") + "] " + _message.get("alert.course.noquantity"); isValid = false; }

		//제한-중복신청검사
		if(0 == cinfo.i("price")) {
			DataSet cuinfo = courseUser.find(
				"user_id = " + userId + " AND course_id = ? AND end_date >= '" + m.time("yyyyMMdd") + "' AND status NOT IN (-1, -4)"
				, new Integer[] { temp.i("product_id") }, "*"
			);
			if(cuinfo.next()) {
				if(cuinfo.i("status") == 0) failed += "\\n[" + cinfo.s("course_nm") + "] " + _message.get("alert.course_user.wait_approve");
				else if(cuinfo.i("status") == 3) failed += "\\n[" + cinfo.s("course_nm") + "] " + _message.get("alert.course_user.wait_cancel");
				else failed += "\\n[" + cinfo.s("course_nm") + "] " + _message.get("alert.course.applied");
				isValid = false;
			}
		}

		//등록-가격정보
		temp.put("product_nm", cinfo.s("course_nm"));
		temp.put("product_id", cinfo.i("id"));
		temp.put("renew_yn", "N");
		temp.put("renew_id", 0);
		temp.put("price", cinfo.i("price"));
		temp.put("disc_group_yn", cinfo.s("disc_group_yn"));

	} else if("c_renew".equals(temp.s("product_type"))) {
		if(!"D".equals(type)) { failed += "\\n" + _message.get("alert.order_item.extend_cart"); isValid = false; }

		//과정연장
		DataSet crinfo = courseUser.query(
			"SELECT a.*, c.id course_id, c.course_nm, c.course_type, c.onoff_type, c.lesson_day, c.renew_price, c.renew_yn, c.disc_group_yn, oi.renew_id "
			+ " FROM " + courseUser.table + " a "
			+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
			+ " LEFT JOIN " + orderItem.table + " oi ON a.id = oi.renew_id AND oi.status = 2 "
			+ " WHERE a.id = ? AND a.user_id = " + userId + " AND a.status IN (1, 3) "
			//+ " AND '" + today + "' BETWEEN a.start_date AND a.end_date "
			, new Integer[] { temp.i("product_id") }
		);
		if(!crinfo.next()) { failed += "\\n" + _message.get("alert.course_user.nodata") + " [CUINFO]"; isValid = false; }
		if(1 > crinfo.i("lesson_day") || "".equals(crinfo.s("end_date"))) { failed += "\\n" + _message.get("alert.course_user.nodata") + " [DTINFO]"; isValid = false; }

		//제한-수강기간
		if("".equals(crinfo.s("start_date")) || "".equals(crinfo.s("end_date")) || 0 > m.diffDate("D", m.time("yyyyMMdd"), crinfo.s("end_date")) || 0 < m.diffDate("D", m.time("yyyyMMdd"), crinfo.s("start_date"))) {
			failed += "\\n" + _message.get("alert.course_user.noperiod_study") + " 학습기간 중에만 연장이 가능합니다.";
			isValid = false;
		}

		//제한-진행중주문
		if(isValid && 0 < crinfo.i("renew_id")) { failed += "\\n[" + crinfo.s("course_nm") + "] " + _message.get("alert.order_item.extend_progress"); isValid = false; }

		//제한
		if(isValid && (!crinfo.b("renew_yn") || !"A".equals(crinfo.s("course_type")) || !"N".equals(crinfo.s("onoff_type")) || (0 > m.diffDate("D", today, crinfo.s("end_date"))))) {
			failed += "\\n[" + crinfo.s("course_nm") + "] " + _message.get("alert.course.noextend");
			isValid = false;
		}

		m.log("cart_common", crinfo.toString());

		if(isValid) {
			//등록-가격정보
			temp.put("product_nm", "[" + _message.get("course.extend.prefix") + m.time(_message.get("format.date.dot"), m.addDate("D", crinfo.i("lesson_day"), crinfo.s("end_date"))) + _message.get("course.extend.suffix") + "] " + crinfo.s("course_nm"));
			temp.put("product_id", crinfo.i("course_id"));
			temp.put("renew_yn", "Y");
			temp.put("renew_id", crinfo.i("id"));
			temp.put("price", crinfo.i("renew_price"));
			temp.put("disc_group_yn", crinfo.s("disc_group_yn"));
		}

	} else if("book".equals(temp.s("product_type"))) {
		//도서
		DataSet binfo = book.find("id = ? AND sale_yn = 'Y' AND status = 1 AND site_id = " + siteId, new Integer[] { temp.i("product_id") });
		if(!binfo.next()) { failed += "\\n" + _message.get("alert.book.nodata"); isValid = false; }

		//등록-가격정보
		temp.put("product_nm", binfo.s("book_nm"));
		temp.put("product_id", binfo.i("id"));
		temp.put("renew_yn", "N");
		temp.put("renew_id", 0);
		temp.put("price", binfo.i("book_price"));
		temp.put("disc_group_yn", binfo.s("disc_group_yn"));

	} else if("freepass".equals(temp.s("product_type"))) {
		//프리패스
		DataSet finfo = freepass.query(
			"SELECT a.*, (CASE WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' ELSE 'N' END) is_request "
			+ " FROM " + freepass.table + " a "
			+ " WHERE a.id = ? AND a.sale_yn = 'Y' AND a.status = 1 AND a.site_id = " + siteId
			, new Integer[] { temp.i("product_id") }
		);
		if(!finfo.next()) { failed += "\\n" + _message.get("alert.freepass.nodata"); isValid = false; }

		//제한-신청기간검사
		if(!"Y".equals(finfo.s("is_request"))) { failed += "\\n[" + finfo.s("freepass_nm") + "] " + _message.get("alert.course.noperiod"); isValid = false; }

		//중복신청검사
		DataSet fuinfo = freepassUser.find(
			"user_id = " + userId + " AND freepass_id = ? AND end_date >= '" + m.time("yyyyMMdd") + "' AND status IN (1, 2, 3)"
			, new Integer[] { temp.i("product_id") }, "*"
		);
		if(fuinfo.next()) { failed += "\\n[" + finfo.s("freepass_nm") + "] " + _message.get("alert.freepass.applied"); isValid = false; }

		//등록-가격정보
		temp.put("product_nm", finfo.s("freepass_nm"));
		temp.put("product_id", finfo.i("id"));
		temp.put("renew_yn", "N");
		temp.put("renew_id", 0);
		temp.put("price", finfo.i("price"));
		temp.put("disc_group_yn", finfo.s("disc_group_yn"));

	}

	//추가
	if(isValid) items.addRow(temp.getRow());
}

//실패알림
if(!"".equals(failed)) { m.jsAlert(_message.get("alert.order_item.failed_reason") + "\\n" + failed); }

//제한-상품갯수
if(1 > items.size()) {
	//m.jsReplace("../order/cart_list.jsp", "parent");
	return;
}

//갱신-바로구매 결제 대기 중이던 상품을 카트로 옮김
orderItem.execute("UPDATE " + orderItem.table + " SET status = 10, order_id = -99 WHERE status = 20 AND user_id = " + userId);

//그룹할인률
DataSet uinfo = new DataSet();
uinfo.addRow();
uinfo.put("id", userId);
uinfo.put("site_id", siteId);
uinfo.put("dept_id", userDeptId);
String tmpGroups = group.getUserGroup(uinfo);
int groupDisc = group.getMaxDiscRatio();

//등록
Vector<String> rollback = new Vector<String>();
int newOrderId = "D".equals(type) ? order.getSequence() : -99;
items.first();
while(items.next()) {
	orderItem.clear();

	String productType = items.s("product_type");
	int newId = orderItem.getSequence(); rollback.add("" + newId);
	int productId = items.i("product_id");
	int courseId = ("course".equals(productType) || "c_renew".equals(productType)) ? productId : 0;
	int renewId = "c_renew".equals(productType) ? items.i("renew_id") : 0;
	int quantity = "book".equals(productType) ? items.i("quantity") : 1;
	if(1 > items.i("quantity")) quantity = 1;
	else if(1000 < items.i("quantity")) quantity = 1000;

	//삭제-카트에 동일상품 있는 경우
	DataSet lastItems = orderItem.find("product_type = ? AND product_id = ? AND user_id = " + userId + " AND status = 10", new String[] {productType, productId + ""});
	while(lastItems.next()) {
		orderItem.deleteCartItem(lastItems.i("id"), lastItems.i("coupon_user_id"));
	}

	orderItem.item("id", newId);
	orderItem.item("site_id", siteId);
	orderItem.item("order_id", newOrderId);
	orderItem.item("user_id", userId);
	orderItem.item("product_nm", items.s("product_nm"));
	orderItem.item("product_type", productType);
	orderItem.item("product_id", productId);
	orderItem.item("course_id", courseId);
	orderItem.item("renew_yn", 0 < renewId ? "Y" : "N");
	orderItem.item("renew_id", renewId);
	orderItem.item("quantity", quantity);
	orderItem.item("unit_price", items.i("price"));
	orderItem.item("price", items.i("price") * quantity);
	orderItem.item("disc_price", 0);

	//그룹할인
	if(items.b("disc_group_yn") && 0 < groupDisc) {
		int discGroupPrice = items.i("price") * quantity * groupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
		orderItem.item("disc_group_price", discGroupPrice);
		orderItem.item("pay_price", (items.i("price") - discGroupPrice) * quantity);
	} else {
		orderItem.item("disc_group_price", 0);
		orderItem.item("pay_price", items.i("price") * quantity);
	}

	orderItem.item("coupon_price", 0);
	orderItem.item("reg_date", now);
	orderItem.item("status", "D".equals(type) ? 20 : 10);
	if(!orderItem.insert()) {
		if(!orderItem.delete("id IN (" + m.join(",", rollback.toArray()) + ")")) { }
		m.jsAlert(_message.get("alert.common.error_insert"));
		break;
	}
}

if("D".equals(type)) {
	//바로구매시 결제페이지로
	//세션
	mSession.put("last_order_id", newOrderId);
	mSession.save();

	m.jsReplace("../order/payment.jsp?oek=" + order.getOrderEk(newOrderId, userId)/* + "&oid=" + m.encode(""+newOrderId)*/, "parent");
	return;
} else {
	//아니면 장바구니로
	//m.jsReplace("../order/cart_list.jsp", "parent");
}

p.setLayout("blank");
p.setBody("order.cart_common_insert");
p.setVar("message_inserted", _message.get("alert.order_item.inserted"));
p.display();

%>