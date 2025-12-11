<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(66, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserOutDao userOut = new UserOutDao();
UserDao user = new UserDao(isBlindUser);

//폼체크
//f.addElement("s_confirm", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(20);
lm.setTable(
	userOut.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id "
	+ " LEFT JOIN " + user.table + " c ON a.admin_id = c.id "
);
lm.setFields("a.user_id, a.out_type, a.memo, a.out_date, a.reg_date, b.id, b.login_id, b.user_nm, b.status, c.user_nm admin_nm");
//if("1".equals(f.get("s_confirm"))) lm.addWhere("(a.out_date != '' OR a.out_date IS NOT NULL OR a.admin_id != '' OR a.admin_id IS NOT NULL)");
//else if("0".equals(f.get("s_confirm"))) lm.addWhere("(a.out_date = '' OR a.out_date IS NULL OR a.admin_id = '' OR a.admin_id IS NULL)");
lm.addSearch("b.status", f.get("s_status"));
lm.addWhere("b.site_id = " + siteId + "");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("b.user_nm, b.login_id", f.get("s_keyword"), "LIKE");
}
lm.addWhere("a.status != -1");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("out_date_conv", !"".equals(list.s("out_date")) ? m.time("yyyy.MM.dd", list.s("out_date")) : "-");
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("admin_nm_conv", !"".equals(list.s("admin_nm")) ? list.s("admin_nm") : "-");
	int isConfirm = !"".equals(list.s("out_date")) && -1 == list.i("status") ? 1 : 0;
	list.put("confirm_status", m.getItem(""+isConfirm, userOut.statusList));
	list.put("confirm_block", isConfirm == 1);
	user.maskInfo(list); //마스킹
	if(-1 == list.i("status")) list.put("user_nm", "[탈퇴]");
}

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//출력
p.setBody("user.out_list");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setLoop("status_list", m.arr2loop(userOut.statusList));
p.display();

%>