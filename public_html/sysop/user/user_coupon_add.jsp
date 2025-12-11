<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int sid = m.ri("sid") == 0 ? siteId : m.ri("sid");
int cuid = m.ri("cuid");
if(cuid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
CouponUserDao couponUser = new CouponUserDao();

//폼체크
f.addElement("s_kind", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//정보
DataSet info = couponUser.find("id = " + cuid + " AND user_id = 0");
if(!info.next()) {
	m.js("parent.opener.location.href = parent.opener.location.href;");
	m.jsErrClose("이미 사용된 쿠폰이거나 쿠폰정보가 없습니다.");
	return;
}

if("Add".equals(m.rs("mode"))) {
	if("".equals(m.ri("uid"))) { m.jsAlert("회원정보가 잘못되었습니다."); return; }

	couponUser.item("user_id", m.ri("uid"));
	couponUser.item("reg_date", m.time("yyyyMMddHHmmss"));

	if(!couponUser.update("id = " + cuid)) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.js("parent.opener.location.href = parent.opener.location.href;");
	m.js("parent.window.close();");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	user.table + " a"
);
lm.setFields("a.*");
lm.addWhere("a.status = 1 AND a.site_id = " + sid);
lm.addSearch("a.user_kind", f.get("s_kind"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.login_id, a.user_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.request("ord")) ? m.request("ord") : "a.reg_date ASC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("kind_conv", m.getItem(list.s("user_kind"), user.kinds));
}

//출력
p.setLayout("pop");
p.setBody("user.user_coupon_add");
p.setVar("p_title", "회원 선택");
p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setVar("form_script", f.getScript());
p.setVar("sid", sid);
p.setVar("cuid", cuid);
p.setLoop("kind_list", m.arr2loop(user.kinds));
p.display();
%>