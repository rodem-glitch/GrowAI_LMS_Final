<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!(Menu.accessible(6, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int bid = m.ri("bid");
String picker = m.rs("picker");
if(bid == 0 || "".equals(picker)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

//폼체크
f.addElement("s_user_kind", null, null);
f.addElement("s_dept", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	user.table + " a "
	+ " LEFT JOIN " + userDept.table + " d ON a.dept_id = d.id "
);
lm.setFields("a.*, d.dept_nm");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
if(0 < f.getInt("s_dept")) lm.addWhere("a.dept_id IN (" + userDept.getSubIdx(siteId, f.getInt("s_dept")) + ")");
lm.addSearch("a.user_kind", f.get("s_user_kind"));
//lm.addSearch("a.dept_id", f.get("s_dept"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.user_nm,a.login_id,a.email", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.user_nm ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	if(0 < list.i("dept_id")) {	
		list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
	} else {	
		list.put("dept_nm", "[미소속]");
		list.put("dept_nm_conv", "[미소속]");
	}	

	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "-" );

	user.maskInfo(list);
}

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//출력
p.setLayout("pop");
p.setBody("board.user_add");
p.setVar("p_title", "관리자 추가");
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("dept_list", userDept.getList(siteId));
p.display();

%>