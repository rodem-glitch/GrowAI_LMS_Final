<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.26

//접근권한
if(!Menu.accessible(19, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
CourseUserDao courseUser = new CourseUserDao();
OrderDao order = new OrderDao();

//폼체크
f.addElement("s_user_kind", null, null);
f.addElement("s_dept", null, null);
f.addElement("s_course_cnt", "0", "hname:'수강건수', option:'number', min:'0', max:'999'");
f.addElement("s_pay_price_sum", "0", "hname:'실결제금액', option:'number', min:'0', max:'99999999'");
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
	user.table + " a "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
	+ (courseManagerBlock ? " INNER JOIN " + courseUser.table + " cu ON cu.user_id = a.id AND cu.course_id IN (" + manageCourses + ") " : "")
);
lm.setFields(
	" a.*, d.dept_nm "
	+ " , (SELECT COUNT(*) FROM " + courseUser.table + " WHERE user_id = a.id AND status IN (1, 3)) course_cnt "
	+ " , IFNULL((SELECT SUM(pay_price) FROM " + order.table + " WHERE user_id = a.id AND status IN (1, 3)), 0) pay_price_sum "
);
lm.addWhere("a.status NOT IN (-1, 31)");
lm.addWhere("a.site_id = " + siteId + "");
if(deptManagerBlock) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")");
if(0 < f.getInt("s_dept")) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");
else if(-99 == f.getInt("s_dept")) lm.addWhere("a.dept_id < 1");
//if(0 < f.getInt("s_course_cnt")) lm.addWhere("course_cnt >= " + f.getInt("s_course_cnt"));
//if(0 < f.getInt("s_pay_price_sum")) lm.addWhere("pay_price_sum >= " + f.getInt("s_pay_price_sum"));
lm.addSearch("a.user_kind", f.get("s_user_kind"));
//lm.addSearch("a.dept_id", f.get("s_dept"));
lm.addSearch("a.status", f.get("s_status"));
if("a.mobile".equals(f.get("s_field"))) lm.addSearch("a.mobile", f.get("s_keyword"), "LIKE");
else if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.login_id, a.user_nm, a.email, a.etc1, a.etc2, a.etc3, a.etc4, a.etc5", f.get("s_keyword"), "LIKE");
if(courseManagerBlock) lm.setGroupBy("a.id");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
//m.p(list);
while(list.next()) {
	list.put("course_cnt_conv", m.nf(list.i("course_cnt")));
	list.put("pay_price_sum_conv", m.nf(list.i("pay_price_sum")));

	if(0 < list.i("dept_id")) {
		list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
	} else {
		list.put("dept_nm", "[미소속]");
		list.put("dept_nm_conv", "[미소속]");
	}
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), user.statusList));
	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "" );

	list.put("email_yn_conv", m.getItem(list.s("email_yn"), user.receiveYn));
	list.put("sms_yn_conv", m.getItem(list.s("sms_yn"), user.receiveYn));

	list.put("conn_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("conn_date")));
	list.put("birthday_conv", list.s("birthday").length() == 8 ? m.time("yyyy.MM.dd", list.s("birthday")) : "");
	list.put("gender_conv", m.getItem(list.s("gender"), user.genders));
	list.put("user_kind_conv", m.getItem(list.s("user_kind"), user.kinds));
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "회원관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>회원ID", "dept_nm_conv=>소속", "login_id=>로그인아이디", "user_nm=>성명", "mobile_conv=>휴대전화", "email=>이메일", "zipcode=>우편번호", "new_addr=>주소", "addr_dtl=>상세주소", "gender_conv=>성별", "birthday_conv=>생년월일", "etc1=>" + SiteConfig.s("user_etc_nm1"), "etc2=>" + SiteConfig.s("user_etc_nm2"), "etc3=>" + SiteConfig.s("user_etc_nm3"), "etc4=>" + SiteConfig.s("user_etc_nm4"), "etc5=>" + SiteConfig.s("user_etc_nm5"), "course_cnt=>수강건수", "pay_price_sum=>실결제금액", "email_yn_conv=>이메일수신동의여부", "sms_yn_conv=>SMS수신동의여부", "conn_date_conv=>최근접속일", "reg_date_conv=>등록일", "status_conv=>상태" }, "회원관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("user.user_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("SITE_CONFIG", SiteConfig.getArr("user_etc_"));
p.setLoop("kinds", m.arr2loop(user.kinds));
p.setLoop("dept_list", userDept.getList(siteId, userKind, userDeptId));
p.setLoop("status_list", m.arr2loop(user.statusList));
p.display();

%>