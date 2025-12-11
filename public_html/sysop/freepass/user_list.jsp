<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(130, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
FreepassDao freepass = new FreepassDao(siteId);
FreepassUserDao freepassUser = new FreepassUserDao(siteId);
CourseUserDao courseUser = new CourseUserDao();

OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();

//처리
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

//폼체크
f.addElement("s_user_kind", null, null);
f.addElement("s_dept", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 60000 : f.getInt("s_listnum", 20));
lm.setTable(
	freepassUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
	+ " INNER JOIN " + freepass.table + " f ON a.freepass_id = f.id "
	+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id "
	+ " LEFT JOIN " + orderItem.table + " oi ON a.order_item_id = oi.id "
	+ (courseManagerBlock ? " INNER JOIN " + courseUser.table + " cu ON cu.user_id = a.id AND cu.course_id IN (" + manageCourses + ") " : "")
);
lm.setFields("a.*, u.user_nm, u.login_id, f.freepass_nm, o.paymethod, oi.price, oi.pay_price");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
if(deptManagerBlock) lm.addWhere("u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")");
//lm.addSearch("a.dept_id", f.get("s_dept"));
lm.addSearch("a.freepass_id", m.rs("fid"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("u.login_id, u.user_nm, u.email, u.etc1, u.etc2, u.etc3, u.etc4, u.etc5", f.get("s_keyword"), "LIKE");
if(courseManagerBlock) lm.setGroupBy("a.id");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("start_date_conv", m.time("yyyy.MM.dd", list.s("start_date")));
	list.put("end_date_conv", m.time("yyyy.MM.dd", list.s("end_date")));
	list.put("start_date_conv2", m.time("yyyy-MM-dd", list.s("start_date")));
	list.put("end_date_conv2", m.time("yyyy-MM-dd", list.s("end_date")));

	list.put("deposit_block", "90".equals(list.s("paymethod")) && 2 == list.i("status"));
	list.put("order_block", 0 < list.i("order_id"));
	list.put("pay_price_conv", m.nf(list.i("pay_price")));

	list.put("limit_cnt_conv", 0 < list.i("limit_cnt") ? m.nf(list.i("limit_cnt")) + "회" : "무제한");
	list.put("use_cnt_conv", m.nf(list.i("use_cnt")));
	list.put("status_conv", m.getItem(list.s("status"), freepassUser.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "회원관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "dept_nm_conv=>소속", "login_id=>로그인아이디", "user_nm=>성명", "mobile_conv=>휴대전화", "email=>이메일", "zipcode=>우편번호", "new_addr=>주소", "addr_dtl=>상세주소", "gender_conv=>성별", "birthday_conv=>생년월일", "etc1=>" + SiteConfig.s("user_etc_nm1"), "etc2=>" + SiteConfig.s("user_etc_nm2"), "etc3=>" + SiteConfig.s("user_etc_nm3"), "etc4=>" + SiteConfig.s("user_etc_nm4"), "etc5=>" + SiteConfig.s("user_etc_nm5"), "conn_date_conv=>최근접속일", "reg_date_conv=>등록일", "status_conv=>상태" }, "회원관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("freepass.user_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("SITE_CONFIG", SiteConfig.getArr("user_etc_"));
p.setLoop("kinds", m.arr2loop(user.kinds));
p.setLoop("dept_list", userDept.getList(siteId, userKind, userDeptId));
p.setLoop("status_list", m.arr2loop(freepassUser.statusList));

p.setVar("tab_user", "current");

p.display();

%>