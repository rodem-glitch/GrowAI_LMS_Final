<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(18, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
GroupDao group = new GroupDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
GroupUserDao groupUser = new GroupUserDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = group.find("id = '" + id + "' AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("group_nm", info.s("group_nm"), "hname:'그룹명', required:'Y'");
f.addElement("description", null, "hname:'설명'");
f.addElement("disc_ratio", info.i("disc_ratio"), "hname:'그룹할인률', option:'number', min:'0', max:'100', required:'Y'");
f.addElement("status", info.i("status"), "hname:'상태', option:'number', required:'Y'");

//수정
if(m.isPost() && f.validate()) {

	group.item("group_nm", f.get("group_nm"));
	group.item("description", f.get("description"));
	group.item("disc_ratio", f.getInt("disc_ratio"));
	group.item("depts", "");
	if(f.getArr("dp_idx") != null) group.item("depts", "|" + m.join("|", f.getArr("dp_idx")) + "|");
	group.item("status", f.getInt("status"));

	if(!group.update("id = '" + id + "'")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("group_list.jsp?" + m.qs("id"), "parent");
	return;
}

//목록
String depts = !"".equals(info.s("depts")) ? m.replace(info.s("depts").substring(1, info.s("depts").length()-1), "|", ",") : "";
DataSet list = user.query(
	" SELECT a.*, d.dept_nm "
	+ " FROM " + user.table + " a "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 1"
	+ (!"".equals(depts) ? " AND ( a.dept_id IN (" + depts + ") OR " : "  AND ( ")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + groupUser.table + " "
		+ " WHERE group_id = " + id + " AND add_type = 'A' "
		+ " AND user_id = a.id "
	+ " ) ) AND NOT EXISTS ( "
		+ " SELECT 1 FROM " + groupUser.table + " "
		+ " WHERE group_id = " + id + " AND add_type = 'D' "
		+ " AND user_id = a.id "
	+ " ) "
);
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), user.statusList));
	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "-" );

	list.put("conn_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("conn_date")));
	list.put("birthday_conv", list.s("birthday").length() == 8 ? m.time("yyyy.MM.dd", list.s("birthday")) : "");
	list.put("gender_conv", m.getItem(list.s("gender"), user.genders));
	user.maskInfo(list);
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "회원그룹관리-" + info.s("group_nm") + "(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "dept_nm=>소속", "login_id=>로그인아이디", "user_nm=>성명", "mobile_conv=>휴대전화", "email=>이메일", "zipcode=>우편번호", "addr=>구주소", "new_addr=>도로명주소", "gender_conv=>성별", "birthday_conv=>생년월일", "etc1=>기타1", "etc2=>기타2", "etc3=>기타3", "etc4=>기타4", "etc5=>기타5", "conn_date_conv=>최근접속일", "reg_date_conv=>등록일", "status_conv=>상태" }, "회원그룹관리-" + info.s("group_nm") + "(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//포맷팅
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("user_cnt", m.nf(list.size()));
/* info.put("user_cnt", user.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + user.table + " a "
	+ " WHERE "
	+ (!"".equals(depts) ? " a.status = 1 AND ( a.dept_id IN (" + depts + ") OR " : " ( a.status = 1 AND ")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + groupUser.table + " "
		+ " WHERE group_id = " + id + " AND add_type = 'A' "
		+ " AND user_id = a.id "
	+ " ) ) AND NOT EXISTS ( "
		+ " SELECT 1 FROM " + groupUser.table + " "
		+ " WHERE group_id = " + id + " AND add_type = 'D' "
		+ " AND user_id = a.id "
	+ " ) "
)); */

//목록
DataSet inlist = groupUser.query(
	"SELECT u.*, d.dept_nm FROM " + groupUser.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " LEFT JOIN " + userDept.table + " d ON u.dept_id = d.id "
	+ " WHERE a.add_type = 'A' AND a.group_id = " + id + " "
);
while(inlist.next()) {
	inlist.put("user_kind_conv", m.getItem(inlist.s("user_kind"), user.kinds));
	if(0 < inlist.i("dept_id")) {	
		inlist.put("dept_nm_conv", userDept.getNames(inlist.i("dept_id")));
	} else {	
		inlist.put("dept_nm", "[미소속]");
		inlist.put("dept_nm_conv", "[미소속]");
	}
	user.maskInfo(inlist);
}
DataSet exlist = groupUser.query(
	"SELECT u.*, d.dept_nm FROM " + groupUser.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " LEFT JOIN " + userDept.table + " d ON u.dept_id = d.id "
	+ " WHERE a.add_type = 'D' AND a.group_id = " + id + " "
);
while(exlist.next()) {
	exlist.put("user_kind_conv", m.getItem(exlist.s("user_kind"), user.kinds));
	if(0 < exlist.i("dept_id")) {	
		exlist.put("dept_nm_conv", userDept.getNames(exlist.i("dept_id")));
	} else {	
		exlist.put("dept_nm", "[미소속]");
		exlist.put("dept_nm_conv", "[미소속]");
	}
	user.maskInfo(exlist);
}

//기록-개인정보조회
DataSet totlist = new DataSet();
totlist.addAll(inlist);
totlist.addAll(exlist);
if(totlist.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, totlist.size(), "이러닝 운영", totlist);
/*
DataSet dlist = userDept.query(
	"SELECT a.* "
	+ ", ( SELECT COUNT(*) FROM " + user.table + " WHERE dept_id = a.id AND status != -1 ) user_cnt "
	+ " FROM " + userDept.table + " a "
	+ " WHERE a.status = 1 AND a.site_id = " + siteId + " "
	+ " ORDER BY a.sort ASC "
);
while(dlist.next()) {
	dlist.put("user_cnt_conv", m.nf(dlist.i("user_cnt")));
}
*/

//소속인원
Hashtable<String, String> deptMap = new Hashtable<String, String>();
DataSet ulist = user.query(
	" SELECT a.dept_id, COUNT(*) cnt "
	+ " FROM " + user.table + " a "
	+ " INNER JOIN " + userDept.table + " d on a.dept_id = d.id "
	+ " WHERE a.site_id = " + siteId + " AND a.status != -1 "
	+ " GROUP BY a.dept_id "
);
while(ulist.next()) {
	String key = ulist.s("dept_id");
	if(!deptMap.containsKey(key)) {
		deptMap.put(key, ulist.s("cnt"));
	}
}

//소속
DataSet dlist = userDept.find("status != -1 AND site_id = " + siteId, "*", "parent_id ASC, sort ASC");
while(dlist.next()) {
	String key = dlist.s("id");
	dlist.put("user_cnt", deptMap.containsKey(key) ? deptMap.get(key) : "0");
	dlist.put("user_cnt_conv", m.nf(dlist.i("user_cnt")));

	dlist.put("parent_id", dlist.i("parent_id") == 0 ? "-" : dlist.s("parent_id"));
	dlist.put("checked", !"".equals(dlist.s("mid")) ? "checked" : "");
	dlist.put("status", dlist.b("status"));
}
//출력
p.setBody("user.group_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("dept_list", dlist);
p.setLoop("inlist", inlist);
p.setLoop("exlist", exlist);
p.setVar("dept_cnt", dlist.size());
p.setVar("inlist_cnt", inlist.size());
p.setVar("exlist_cnt", exlist.size());

p.setLoop("status_list", m.arr2loop(group.statusList));
p.display();

%>