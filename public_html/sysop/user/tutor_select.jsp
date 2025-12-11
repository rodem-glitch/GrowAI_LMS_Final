<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String mode = m.rs("mode");
if("".equals(mode)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
TutorDao tutor = new TutorDao();
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("s_dept", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

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
lm.setFields("a.*, t.*, d.dept_nm");
lm.addWhere("a.status = 1");
lm.addWhere("a.tutor_yn = 'Y'");
//lm.addWhere("a.user_kind = 'T'");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.dept_id", f.get("s_dept"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.login_id, t.tutor_nm, t.attached, t.major, a.email", f.get("s_keyword"), "LIKE");
}
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
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "-" );

	list.put("conn_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("conn_date")));
	list.put("birth_date_conv", m.time("yyyy.MM.dd", list.s("birthday")));
	list.put("gender_conv", m.getItem(list.s("gender"), user.genders));
	user.maskInfo(list);
}

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("L", "강사조회", list.size(), "이러닝 운영", list);

//출력
p.setLayout("pop");
p.setBody("user.tutor_select");
p.setVar("p_title", "강사 선택");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setLoop("list", list);

p.setLoop("dept_list", userDept.getList(siteId));
p.setVar(mode + "_block", true);
p.display();

%>