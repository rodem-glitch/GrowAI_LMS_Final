<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(61, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"ktalk_"});

//객체
RefundDao refund = new RefundDao();
UserDao user = new UserDao(isBlindUser);
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseUserLogDao courseUserLog = new CourseUserLogDao();
CourseLessonDao courseLesson = new CourseLessonDao();
BookDao book = new BookDao();
FreepassDao freepass = new FreepassDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
KtalkDao ktalk = new KtalkDao(siteId);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId);

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = refund.query(
	"SELECT a.*, i.product_nm, i.product_type, i.product_id, u.id user_id, u.user_nm, u.login_id, u.mobile, m.user_nm manager_nm "
	//+ " , cu.start_date, cu.end_date "
	+ " FROM " + refund.table + " a "
	+ " INNER JOIN " + orderItem.table + " i ON a.order_item_id = i.id "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " LEFT JOIN " + user.table + " m ON a.manager_id = m.id "
	//+ " LEFT JOIN " + courseUser.table + " cu ON a.course_user_id = cu.id AND cu.status != -1 "
	+ " WHERE a.id = " + id + " "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("mobile_conv", !"".equals(info.s("mobile")) ? info.s("mobile") : "-" );
user.maskInfo(info);

//기록-개인정보조회
if(info.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, info.size(), "이러닝 운영", info);

//정보-주문
DataSet oinfo = order.find("id = " + info.i("order_id") + "");
if(!oinfo.next()) { m.jsError("해당 주문정보가 없습니다."); return; }

//정보-주문항목
DataSet oiinfo = orderItem.find("id = " + info.i("order_item_id") + "");
if(!oiinfo.next()) { m.jsError("해당 주문항목정보가 없습니다."); return; }

//정보-과정
DataSet cinfo = new DataSet();
if("course".equals(info.s("product_type")) || "c_renew".equals(info.s("product_type"))) { cinfo = course.find("id = " + info.i("product_id") + ""); }
else if("book".equals(info.s("product_type"))) { cinfo = book.find("id = " + info.i("product_id") + ""); }
else if("freepass".equals(info.s("product_type"))) { cinfo = freepass.find("id = " + info.i("product_id") + ""); }
if(!cinfo.next()) { m.jsError("해당 과정/도서정보가 없습니다."); return; }

//정보-수강생
DataSet cuinfo = new DataSet();
if("course".equals(info.s("product_type")) && !"P".equals(cinfo.s("onoff_type"))) {
	cuinfo = courseUser.query(
		" SELECT a.* "
		+ " , (SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.course_id AND status = 1) lesson_cnt "
		+ " , (SELECT COUNT(DISTINCT lesson_id) FROM " + courseUserLog.table + " WHERE course_user_id = a.id) study_cnt "
		+ " FROM " + courseUser.table + " a "
		+ " WHERE a.order_id = " + info.i("order_id") + " AND a.course_id = " + info.i("course_id") + " AND a.user_id = " + info.i("user_id")
	);
	if(!cuinfo.next()) { m.jsError("해당 수강생정보가 없습니다."); return; }
}

//폼체크
f.addElement("req_memo", info.s("req_memo"), "hname:'요청사항'");
f.addElement("bank_nm", info.s("bank_nm"), "hname:'은행명'");
f.addElement("account_no", info.s("account_no"), "hname:'은행계좌'");
f.addElement("depositor", info.s("depositor"), "hname:'예금주'");
f.addElement("refund_price", info.s("refund_price"), "hname:'환불금액', option:'number', required:'Y'");
f.addElement("refund_method", info.s("refund_method"), "hname:'환불방법'");
f.addElement("memo", null, "hname:'관리자메모'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y'");
f.addElement("mobile_yn", "Y", "hname:'SMS발송'");

//수정
if(m.isPost() && f.validate()) {
	order.d(out);
	int status = f.getInt("status");

	if(status == 2 && f.getInt("refund_price") == 0) { m.jsAlert("환불금액이 올바르지 않습니다."); return; }

	//제한-환불액
	if(f.getInt("refund_price") > oiinfo.i("pay_price")) {
		m.jsAlert("지불금액보다 환불금액이 더 큽니다. 다시 입력해 주세요.");
		return;
	}

	boolean isDBOK = true;
	String now = m.time("yyyyMMddHHmmss");
	boolean isPart = f.getInt("refund_price") < oiinfo.i("pay_price");

	refund.item("refund_type", isPart ? 1 : 2);
	refund.item("req_memo", f.get("req_memo"));
	refund.item("bank_nm", f.get("bank_nm"));
	refund.item("account_no", f.get("account_no"));
	refund.item("depositor", f.get("depositor"));
	refund.item("refund_price", f.get("refund_price"));
	refund.item("refund_method", f.get("refund_method"));
	refund.item("refund_date", now);
	refund.item("manager_id", userId);
	refund.item("memo", f.get("memo"));
	refund.item("status", status);

	if(!refund.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생하였습니다."); return; }
	else if(status == 2) {

		//주문항목
		orderItem.item("refund_price", status == 2 ? f.getInt("refund_price") : 0);
		orderItem.item("refund_date", status == 2 ? now : "");
		orderItem.item("status", status == 2 ? -2 : (status == 1 ? 3 : 1));
		if(!orderItem.update("id = " + info.i("order_item_id") + "")) isDBOK = false;
		else {
			int refundPrice = orderItem.getOneInt(
				"SELECT SUM(refund_price) FROM " + orderItem.table + " "
				+ " WHERE order_id = " + info.s("order_id") + ""
				+ " AND status IN (1,3,-2) "
			);

			//주문
			order.item("refund_price", refundPrice);
			order.item("refund_date", refundPrice > 0 ? now : "");
			order.item("status", refundPrice > 0 ? ( refundPrice < oinfo.i("pay_price") ? 3 : 4 ) : 1);
			if(!order.update("id = '" + info.s("order_id") + "'")) isDBOK = false;
			else {
				if("course".equals(oiinfo.s("product_type"))) {
					//수강정보
					courseUser.item("status", m.getItem(status, new String[] { "1=>3", "2=>-4", "-1=>1" }));
					if(!courseUser.update("order_item_id = " + info.i("order_item_id") + " AND (package_id = " + info.i("course_id") + " OR course_id = " + info.i("course_id") + ") AND user_id = " + info.i("user_id") + "")) isDBOK = false;
				}
			}
		}

		//Rollback
		if(!isDBOK) {

			//환불
			refund.item("refund_type", info.i("refund_type"));
			refund.item("req_memo", info.s("req_memo"));
			refund.item("bank_nm", info.s("bank_nm"));
			refund.item("account_no", info.s("account_no"));
			refund.item("depositor", info.s("depositor"));
			refund.item("refund_price", info.s("refund_price"));
			refund.item("refund_method", info.s("refund_method"));
			refund.item("refund_date", info.s("refund_date"));
			refund.item("manager_id", info.s("manager_id"));
			refund.item("memo", info.s("memo"));
			refund.item("status", info.s("status"));
			if(!refund.update("id = " + id + "")) {  }

			//주문항목
			orderItem.item("refund_price", oiinfo.i("refund_price"));
			orderItem.item("refund_date", oiinfo.s("refund_date"));
			orderItem.item("status", oiinfo.i("status"));
			if(!orderItem.update("id = " + info.i("order_item_id") + "")) { }


			//주문
			order.item("refund_price", oinfo.i("refund_price"));
			order.item("refund_date", oinfo.s("refund_date"));
			order.item("status", oinfo.i("status"));
			if(!order.update("id = " + info.i("order_id") + "")) { }

			m.jsAlert("수정하는 중 오류가 발생하였습니다.");
			return;
		}

	}

	//SMS
	if("Y".equals(f.get("mobile_yn")) && (status == 2 || status == -1)) {
		info.put("id", info.s("user_id"));
		if(status == -1) {
			info.put("refund_price_conv", 0);
			info.put("refund_type_conv", m.getItem("3", refund.types));
		} else {
			info.put("refund_price_conv", m.nf(f.getInt("refund_price")));
			info.put("refund_type_conv", m.getItem(isPart ? "1" : "2", refund.types));
		}
		info.put("status", status);
		p.setVar("info", info);
		if("Y".equals(siteconfig.s("ktalk_yn"))) {
			p.setVar(info);
			p.setVar("remark_conv", "실제 입금 및 카드취소까지는 일정 시일이 소요되는 경우가 있습니다. 감사합니다.");
			ktalkTemplate.sendKtalk(siteinfo, info, "refund", p);
		} else {
			smsTemplate.sendSms(siteinfo, info, "refund", p);
		}
	}

	m.jsReplace("refund_list.jsp?" + m.qs("id"), "parent");
	return;
}

//포멧팅
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
info.put("refund_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("refund_date")));
info.put("status_conv", m.getItem(info.s("status"), refund.statusList));
info.put("refund_type_conv", m.getItem(info.s("refund_type"), refund.types));

oinfo.put("pay_date_conv", m.time("yyyy.MM.dd HH:mm:ss", oinfo.s("pay_date")));
oinfo.put("price_conv", m.nf(oinfo.i("price")));
oinfo.put("disc_price_conv", m.nf(oinfo.i("disc_price")));
oinfo.put("disc_group_price_conv", m.nf(oinfo.i("disc_group_price")));
oinfo.put("coupon_price_conv", m.nf(oinfo.i("coupon_price")));
oinfo.put("delivery_price_conv", m.nf(oinfo.i("delivery_price")));
oinfo.put("pay_price_conv", m.nf(oinfo.i("pay_price")));
oinfo.put("refund_price_conv", m.nf(oinfo.i("refund_price")));
oinfo.put("refund_date_conv", m.time("yyyy.MM.dd HH:mm:ss", oinfo.s("refund_date")));
oinfo.put("paymethod_conv", m.getItem(oinfo.s("paymethod"), order.methods));
oinfo.put("status_conv", m.getItem(oinfo.s("status"), order.statusList));
oinfo.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", oinfo.s("reg_date")));

oiinfo.put("price_conv", m.nf(oiinfo.i("price")));
oiinfo.put("disc_price_conv", m.nf(oiinfo.i("disc_price")));
oiinfo.put("disc_group_price_conv", m.nf(oiinfo.i("disc_group_price")));
oiinfo.put("coupon_price_conv", m.nf(oiinfo.i("coupon_price")));
oiinfo.put("delivery_price_conv", m.nf(oiinfo.i("delivery_price")));
oiinfo.put("pay_price_conv", m.nf(oiinfo.i("pay_price")));
oiinfo.put("refund_price_conv", m.nf(oiinfo.i("refund_price")));
oiinfo.put("refund_date_conv", m.time("yyyy.MM.dd HH:mm:ss", oiinfo.s("refund_date")));
oiinfo.put("status_conv", m.getItem(oiinfo.s("status"), orderItem.statusList));
oiinfo.put("product_type_conv", m.getItem(oiinfo.s("product_type"), orderItem.ptypes));

boolean estimateBlock = false;
if("course".equals(info.s("product_type")) && !"P".equals(cinfo.s("onoff_type"))) {
	estimateBlock = true;
	cuinfo.put("lesson_day", 1 + m.diffDate("D", cuinfo.s("start_date"), cuinfo.s("end_date")));
	cuinfo.put("study_day", 1 + m.diffDate("D", cuinfo.s("start_date"), m.time("yyyyMMdd", info.s("reg_date"))));
	if(cuinfo.i("lesson_day") < cuinfo.i("study_day")) cuinfo.put("study_day", cuinfo.i("lesson_day"));
	else if(0 > cuinfo.i("study_day")) cuinfo.put("study_day", 0);
	if(cuinfo.i("lesson_cnt") < cuinfo.i("study_cnt")) cuinfo.put("study_cnt", cuinfo.i("lesson_cnt"));
	cuinfo.put("lesson_day_conv", m.nf(cuinfo.i("lesson_day")));
	cuinfo.put("study_day_conv", m.nf(cuinfo.i("study_day")));
	cuinfo.put("lesson_cnt_conv", m.nf(cuinfo.i("lesson_cnt")));
	cuinfo.put("study_cnt_conv", m.nf(cuinfo.i("study_cnt")));

	cuinfo.put("day_ratio", 0 < cuinfo.i("lesson_day") ? cuinfo.i("study_day") / cuinfo.d("lesson_day") * 100 : 0);
	cuinfo.put("cnt_ratio", 0 < cuinfo.i("lesson_cnt") ? cuinfo.i("study_cnt") / cuinfo.d("lesson_cnt") * 100 : 0);
	cuinfo.put("day_ratio_conv", m.nf(cuinfo.d("day_ratio"), 2));
	cuinfo.put("cnt_ratio_conv", m.nf(cuinfo.d("cnt_ratio"), 2));

	cuinfo.put("day_price", oiinfo.i("pay_price") * cuinfo.d("day_ratio") / 100.0);
	cuinfo.put("cnt_price", oiinfo.i("pay_price") * cuinfo.d("cnt_ratio") / 100.0);
	cuinfo.put("day_price_conv", m.nf(cuinfo.d("day_price"), 0));
	cuinfo.put("cnt_price_conv", m.nf(cuinfo.d("cnt_price"), 0));
}
//출력
p.setBody("order.refund_insert");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar("modify", true);
p.setVar(info);

p.setVar("order", oinfo);
p.setVar("orderitem", oiinfo);
p.setVar("cuinfo", cuinfo);

p.setVar("estimate_block", estimateBlock);
p.setLoop("refund_methods", m.arr2loop(refund.refundMethods));
p.setLoop("status_list", m.arr2loop(refund.statusList));
p.display();

%>