<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(17, userId, userKind) || (!isUserMaster && !"S".equals(userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("s_dept", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
	user.table + " a "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
);
lm.setFields("a.*, d.dept_nm");
lm.addWhere("a.status != -1");
lm.addWhere("a.user_kind IN ('C', 'D', 'A', 'S')");
lm.addWhere("a.site_id = " + siteinfo.i("id") + "");
if(0 < f.getInt("s_dept")) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");
//lm.addSearch("a.dept_id", f.get("s_dept"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.login_id, a.user_nm, a.email", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	if(0 < list.i("dept_id")) {	
		list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
	} else {	
		list.put("dept_nm", "[미소속]");
		list.put("dept_nm_conv", "[미소속]");
	}	

	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), user.statusList));
	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "" );

	list.put("conn_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("conn_date")));
	list.put("birth_date_conv", m.time("yyyy.MM.dd", list.s("birthday")));
	list.put("gender_conv", m.getItem(list.s("gender"), user.genders));
	list.put("user_kind_conv", m.getItem(list.s("user_kind"), user.kinds));
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "관리자관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "dept_nm=>소속", "user_kind_conv=>유형","login_id=>회원아이디", "user_nm=>관리자명", "mobile_conv=>휴대전화", "email=>이메일", "zipcode=>우편번호", "addr=>구주소", "new_addr=>도로명주소", "gender_conv=>성별", "birthday_conv=>생년월일", "etc1=>기타1", "etc2=>기타2", "etc3=>기타3", "etc4=>기타4", "etc5=>기타5", "conn_date_conv=>최근접속일", "reg_date_conv=>등록일", "status_conv=>상태" }, "관리자관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}


//출력
p.setBody("user.admin_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("dept_list", userDept.getList(siteId));
p.setLoop("status_list", m.arr2loop(user.statusList));
p.display();

%>