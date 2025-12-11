<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(131, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
CourseUserDao courseUser = new CourseUserDao();

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
lm.setListNum("excel".equals(m.rs("mode")) ? 1000000 : f.getInt("s_listnum", 20));
lm.setTable(
	user.table + " a "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
	+ (courseManagerBlock ? " INNER JOIN " + courseUser.table + " cu ON cu.user_id = a.id AND cu.course_id IN (" + manageCourses + ") " : "")
);
lm.setFields("a.*, d.dept_nm");
lm.addWhere("a.status NOT IN (-1, 31)");
lm.addWhere("a.site_id = " + siteId + "");
if(deptManagerBlock) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")");
if(0 < f.getInt("s_dept")) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");
lm.addSearch("a.user_kind", f.get("s_user_kind"));
//lm.addSearch("a.dept_id", f.get("s_dept"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.login_id, a.user_nm, a.email, a.etc1, a.etc2, a.etc3, a.etc4, a.etc5", f.get("s_keyword"), "LIKE");
if(courseManagerBlock) lm.setGroupBy("a.id");
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
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), user.statusList));
	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "" );

	list.put("conn_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("conn_date")));
	list.put("birthday_conv", list.s("birthday").length() == 8 ? m.time("yyyy.MM.dd", list.s("birthday")) : "");
	list.put("gender_conv", m.getItem(list.s("gender"), user.genders));
	list.put("user_kind_conv", m.getItem(list.s("user_kind"), user.kinds));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "회원관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "dept_nm_conv=>소속", "login_id=>로그인아이디", "user_nm=>성명", "mobile_conv=>휴대전화", "email=>이메일", "zipcode=>우편번호", "new_addr=>주소", "addr_dtl=>상세주소", "gender_conv=>성별", "birthday_conv=>생년월일", "etc1=>" + SiteConfig.s("user_etc_nm1"), "etc2=>" + SiteConfig.s("user_etc_nm2"), "etc3=>" + SiteConfig.s("user_etc_nm3"), "etc4=>" + SiteConfig.s("user_etc_nm4"), "etc5=>" + SiteConfig.s("user_etc_nm5"), "conn_date_conv=>최근접속일", "reg_date_conv=>등록일", "status_conv=>상태" }, "회원관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("course.user_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("SITE_CONFIG", SiteConfig.getArr("user_etc_"));
p.setLoop("kinds", m.arr2loop(user.kinds));
p.setLoop("dept_list", userDept.getList(siteId, userKind, userDeptId));
p.setLoop("status_list", m.arr2loop(user.statusList));
p.display();

%>