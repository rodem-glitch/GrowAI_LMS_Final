<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(120, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
BookDao book = new BookDao();
BookUserDao bookUser = new BookUserDao();
UserDao user = new UserDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

//입금확인
if("deposit".equals(m.rs("mode"))) {
	//기본키
	String oid = m.rs("oid");
	if("".equals(oid)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	if(!order.confirmDeposit(oid, siteinfo)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("입금확인이 완료됐습니다.");
	m.jsReplace("user_list.jsp?" + m.qs("mode,oid"), "parent");
	return;
}

//처리
if(m.isPost()) {

	String[] idx = f.getArr("idx");
	if(idx.length == 0) { m.jsError("선택한 회원이 없습니다."); return; }

	if(-1 == bookUser.execute(
		"UPDATE " + bookUser.table + " SET "
		+ " status = " + f.get("a_status") + " "
		+ " WHERE id IN (" + m.join(",", idx) + ") "
	)) {
		m.jsError("변경처리하는 중 오류가 발생했습니다."); return;
	}

	m.jsReplace("user_list.jsp?" + m.qs("idx"));
	return;
}


//폼체크
f.addElement("s_book", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_type", null, null);
f.addElement("s_reg_sdate", null, null);
f.addElement("s_reg_edate", null, null);
f.addElement("s_complete", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	bookUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
	+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id "
	+ " LEFT JOIN " + orderItem.table + " oi ON a.order_item_id = oi.id "
);
lm.setFields(
	"a.*, u.user_nm, u.login_id, u.email, u.zipcode, u.addr, u.new_addr, u.addr_dtl, u.mobile"
	+ ", b.book_type, b.book_nm, o.paymethod, oi.price, oi.pay_price"
);
lm.addWhere("a.status != -1");
lm.addWhere("u.site_id = " + siteId);
//lm.addWhere("a.book_id = " + bookId + "");
lm.addSearch("a.book_id", f.get("s_book"));
lm.addSearch("b.book_type", f.get("s_type"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_reg_sdate"))) lm.addWhere("a.reg_date >= '" + m.time("yyyyMMdd000000", f.get("s_reg_sdate")) + "'");
if(!"".equals(f.get("s_reg_edate"))) lm.addWhere("a.reg_date <= '" + m.time("yyyyMMdd235959", f.get("s_reg_edate")) + "'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("u.user_nm, u.login_id", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("book_nm_conv", m.cutString(list.s("book_nm"), 60));
	list.put("book_type_conv", m.getItem(list.s("book_type"), book.types));
	list.put("start_date_conv", m.time("yyyy.MM.dd", list.s("start_date")));
	list.put("end_date_conv", m.time("yyyy.MM.dd", list.s("end_date")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), bookUser.statusList));

	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "-" );
	list.put("order_block", 0 < list.i("order_id"));
	
	list.put("deposit_block", "90".equals(list.s("paymethod")) && 2 == list.i("status"));
	list.put("important_block", list.b("deposit_block"));
	list.put("order_block", 0 < list.i("order_id"));

	list.put("pay_price_conv", m.nf(list.i("pay_price")));

	list.put("ROW_CLASS", list.b("important_block") ? "important" : list.s("ROW_CLASS"));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "통합대여관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "user_nm=>수강생명", "login_id=>회원아이디", "onoff_type_conv=>과정구분", "course_nm=>과정명", "progress_ratio=>진도율", "total_score=>총점", "start_date_conv=>학습시작일", "end_date_conv=>학습종료일", "price=>과정정가", "pay_price=>결제금액", "reg_date_conv=>등록일", "status_conv=>상태", "email=>이메일", "zipcode=>우편번호", "addr=>지번주소", "new_addr=>도로명주소", "addr_dtl=>상세주소", "mobile_conv=>휴대전화" }, "수강생관리(" + m.time("yyyy-MM-dd") +")");
	ex.write();
	return;
}

//출력
p.setBody("book.user_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("books", book.getBookList(siteId));
p.setLoop("types", m.arr2loop(book.types));
p.setLoop("status_list", m.arr2loop(bookUser.statusList));
p.display();

%>