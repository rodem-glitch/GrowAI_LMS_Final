<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(16, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
TutorDao tutor = new TutorDao();
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("s_dept", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//변수
boolean sortBlock = adminBlock && "".equals(f.get("s_keyword")) && "".equals(f.get("s_dept")) && "".equals(f.get("s_status"));

//순서저장
if(m.isPost() && sortBlock) {
	String idx[] = m.reqArr("id");
	String sorts[] = m.reqArr("sort");

	if(idx == null || sorts == null) { m.jsError("순서를 정렬할 강사가 없습니다."); return; }

	for(int i = 0; i < idx.length; i++) {
		tutor.item("sort", sorts[i]);
		tutor.update("user_id = " + idx[i] + " AND site_id = " + siteId);
	}

	m.redirect("tutor_list.jsp");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	user.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON t.user_id = a.id "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
);
lm.setFields("a.*, t.tutor_nm, t.sort, d.dept_nm");
lm.addWhere("a.status != -1");
lm.addWhere("a.tutor_yn = 'Y'");
lm.addWhere("a.site_id = " + siteId + "");
if(0 < f.getInt("s_dept")) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");
//lm.addSearch("a.dept_id", f.get("s_dept"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.login_id, t.tutor_nm, t.attached, t.major, a.email", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "t.sort ASC, a.id ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	if(0 < list.i("dept_id")) {	
		list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
	} else {	
		list.put("dept_nm", "[미소속]");
		list.put("dept_nm_conv", "[미소속]");
	}

	if(!"Y".equals(list.s("display_yn"))) list.put("display_yn", "N");
	list.put("display_yn_conv", m.getItem(list.s("display_yn"), user.displayYn));

	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), user.statusList));
	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "" );

	list.put("conn_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("conn_date")));
	list.put("birth_date_conv", m.time("yyyy.MM.dd", list.s("birthday")));
	list.put("gender_conv", m.getItem(list.s("gender"), user.genders));
	list.put("user_kind_conv", m.getItem(list.s("user_kind"), user.kinds));

	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "강사관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "dept_nm=>소속", "login_id=>회원아이디", "user_nm=>강사명", "name_en=>성명(영문)", "mobile_conv=>휴대전화", "email=>이메일", "zipcode=>우편번호", "addr=>구주소", "new_addr=>도로명주소", "gender_conv=>성별", "birthday_conv=>생년월일", "attached=>소속", "ability=>경력사항", "university=>최종대학", "major=>전공", "bank_nm=>은행명", "bank_account=>계좌번호", "etc1=>기타1", "etc2=>기타2", "etc3=>기타3", "etc4=>기타4", "etc5=>기타5", "conn_date_conv=>최근접속일", "reg_date_conv=>등록일", "status_conv=>상태" }, "강사관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("user.tutor_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("sort_block", sortBlock);
p.setLoop("dept_list", userDept.getList(siteId));
p.setLoop("status_list", m.arr2loop(user.statusList));
p.display();

%>