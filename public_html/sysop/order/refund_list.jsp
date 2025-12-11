<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.07.14

//접근권한
if(!Menu.accessible(61, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
RefundDao refund = new RefundDao();
UserDao user = new UserDao(isBlindUser);
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
CourseDao course = new CourseDao();
CourseStepDao step = new CourseStepDao();

//수정중
//삭제
if("del".equals(m.rs("mode"))) {

	int id = m.ri("id");
	int oiid = m.ri("oiid");
	int oid = m.ri("oid");
	if(id == 0 && oiid == 0 && oid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	refund.item("status", -2); //환불내역 삭제 상태값은 -2
	if(!refund.update("id = " + id + " AND site_id = " + siteId + "")) {
		m.jsAlert("삭제하는 중 오류가 발생했습니다."); return;
	}

	//환불하기 전으로 되돌리기
	orderItem.item("status", 1);
	orderItem.item("refund_price", 0);
	orderItem.item("refund_date", "");
	if(!orderItem.update("id = " + oiid + " AND site_id = " + siteId + "")) {
		m.jsAlert("삭제하는 중 오류가 발생했습니다."); return;
	}
	order.item("status", 1);
	order.item("refund_price", 0);
	order.item("refund_date", "");
	if(!order.update("id = " + oid + " AND site_id = " + siteId + "")) {
		m.jsAlert("삭제하는 중 오류가 발생했습니다."); return;
	}

	m.jsAlert("삭제되었습니다.");
	m.jsReplace("refund_list.jsp?" + m.qs("mode,id,oid,oiid"), "parent");
	return;
}


//폼체크
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);

f.addElement("s_course", null, null);
f.addElement("s_ptype", null, null);
f.addElement("s_type", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	refund.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " "
	+ " LEFT JOIN " + orderItem.table + " i ON a.order_item_id = i.id "
	+ " LEFT JOIN " + course.table + " c ON i.course_id = c.id AND c.site_id = " + siteId + " "
	+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id "
	+ " LEFT JOIN " + user.table + " m ON a.manager_id = m.id "
);
lm.setFields(
	"a.* "
	+ ", u.user_nm, u.login_id, c.course_nm "
	+ ", i.pay_price, i.product_type, o.order_nm "
	+ ", i.id oiid, o.id oid"
);
lm.addWhere("a.status IN (1,2,-1)");
lm.addSearch("i.course_id", f.get("s_course"));
lm.addSearch("i.product_type", f.get("s_ptype"));
lm.addSearch("a.refund_type", f.get("s_type"));
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.reg_date", m.time("yyyyMMdd000000", f.get("s_sdate")), ">=");
lm.addSearch("a.reg_date", m.time("yyyyMMdd235959", f.get("s_edate")), "<=");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.order_id, a.user_id, u.user_nm, a.req_memo, a.memo", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(f.get("ord")) ? f.get("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("refund_type_conv", "-");
	if(list.i("status") == 2) list.put("refund_type_conv", m.getItem(list.s("refund_type"), refund.types));
	list.put("pay_price_conv", m.nf(list.i("pay_price")));
	list.put("refund_price_conv", m.nf(list.i("refund_price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), refund.statusList));
	list.put("product_type_conv", m.getItem(list.s("product_type"), orderItem.ptypes));


	list.put("method_conv", m.getItem(list.s("paymethod"), order.methods));
	list.put("refund_method_conv", m.getItem(list.s("refund_method"), refund.refundMethods));
	list.put("refund_date_conv", m.time("yyyy.MM.dd", list.s("refund_date")));
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "환불관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>환불아이디", "user_nm=>회원명","login_id=>회원아이디", "course_id=>과정아이디", "order_id=>주문아이디", "order_item_id=>주문항목아이디", "product_type_conv=>상품구분", "order_nm=>주문명","refund_type_conv=>구분", "req_memo=>요청사항", "method_conv=>결제방법", "bank_nm=>은행명", "account_no=>은행계좌", "depositor=>예금주", "refund_price_conv=>환불금액", "refund_method_conv=>환불방법", "refund_date_conv=>환불일시", "memo=>관리자메모", "reg_date_conv=>등록일", "status_conv=>상태" }, "환불관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("order.refund_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setVar("isMalgn", isMalgnOffice && "malgn".equals(loginId)); //수정중

p.setLoop("status_list", m.arr2loop(refund.statusList));
p.setLoop("ptypes", m.arr2loop(orderItem.ptypes));
p.setLoop("types", m.arr2loop(refund.types));
p.setLoop("course_list", course.getCourseList(siteId));
p.display();

%>