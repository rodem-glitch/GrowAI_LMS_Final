<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String idx = m.rs("idx");
String stype = m.rs("stype");

//객체
UserDao user = new UserDao(isBlindUser);
CourseUserDao courseUser = new CourseUserDao();

ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(200);
lm.setNaviNum(5);
lm.setTable(user.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " +  siteId + "");
lm.addSearch("a.user_kind", f.get("s_user_kind"));
lm.addSearch("a.email_yn", f.get("s_email_yn"));
lm.addSearch("a.sms_yn", f.get("s_sms_yn"));
if(!"".equals(m.rs("cid"))) {
	lm.addWhere("EXISTS ( "
		+ " SELECT id FROM " + courseUser.table + " "
		+ " WHERE user_id = a.id AND course_id = '" + m.rs("cid") + "' AND status IN (1, 3) "
	+ ")");
}
if(!"".equals(idx)) lm.addWhere("a.id NOT IN ('" + m.join("','", idx.split(",")) + "')");
if("email".equals(stype)) lm.addWhere("(a.email IS NOT NULL AND a.email != '')");
if("sms".equals(stype)) lm.addWhere("(a.mobile IS NOT NULL AND a.mobile != '')");

if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.login_id, a.user_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy("a.user_nm ASC, a.id ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	user.maskInfo(list);

	if("email".equals(stype)) {
		list.put("receive_yn_conv", "[" + m.getItem(list.s("email_yn"), user.receiveYn) + "]");
		list.put("target", " - " + list.s("email") + "");
	} else if("sms".equals(stype)) {
		list.put("receive_yn_conv", "[" + m.getItem(list.s("sms_yn"), user.receiveYn) + "]");
		list.put("target", " - " + (!"".equals(list.s("mobile")) ? list.s("mobile") : "") + "");
	} else {
		list.put("target", "");
	}
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", "회원조회", list.size(), "이러닝 운영", list);

//출력
p.setLayout("blank");
p.setBody("user.find_left");
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.display();

%>