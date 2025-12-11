<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근
if(!Menu.accessible(118, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserLoginDao userLogin = new UserLoginDao();
UserDao user = new UserDao(isBlindUser);
MCal mcal = new MCal(10);

//날짜
String today = Malgn.time("yyyyMMdd");
DataSet dinfo = new DataSet(); dinfo.addRow();
dinfo.put("sd", Malgn.time("yyyy-MM-dd", today));
dinfo.put("ed", Malgn.time("yyyy-MM-dd", today));
dinfo.put("sw", Malgn.time("yyyy-MM-dd", mcal.getWeekFirstDate(today)));
dinfo.put("ew", Malgn.time("yyyy-MM-dd", mcal.getWeekLastDate(today)));
dinfo.put("sm", Malgn.time("yyyy-MM-01", today));
dinfo.put("em", Malgn.time("yyyy-MM-dd", mcal.getMonthLastDate(today)));

//폼입력
String sdate = m.rs("s_sdate");
String edate = m.rs("s_edate");

//폼체크
f.addElement("s_sdate", sdate, null);
f.addElement("s_edate", edate, null);
f.addElement("s_admin_yn", null, null);
f.addElement("s_login_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
//lm.setListMode(0);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
	userLogin.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId
);
lm.setFields("a.*, u.user_nm, u.login_id");
lm.addWhere("a.site_id = " + siteId + "");
if(!"".equals(sdate)) lm.addWhere("a.log_date >= '" + Malgn.time("yyyyMMdd", sdate) + "'") ;
if(!"".equals(edate)) lm.addWhere("a.log_date <= '" + Malgn.time("yyyyMMdd", edate) + "'");
lm.addSearch("a.admin_yn", f.get("s_admin_yn"));
lm.addSearch("a.login_type", f.get("s_login_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("u.user_nm, u.login_id, a.agent, a.device, a.ip_addr", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()){
	list.put("admin_yn_conv", Malgn.getItem(list.s("admin_yn"), userLogin.adminYnList));
	list.put("login_type_conv", Malgn.getItem(list.s("login_type"), userLogin.loginTypeList));
	list.put("agent_conv", Malgn.cutString(list.s("agent"), 50));
	list.put("reg_date_conv", Malgn.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")));
	list.put("agent", Malgn.htt(list.s("agent")));

	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "접속이력관리(" + Malgn.time("yyyy.MM.dd") + ").xls");
	ex.setData(list, new  String[] { "__ord=>No", "login_id=>로그인아이디", "user_nm=>회원명", "admin_yn_conv=>접속단", "login_type_conv=>구분", "agent=>브라우저", "device=>기기", "ip_addr=>IP", "reg_date_conv=>등록일시" }, "접속이력관리(" + Malgn.time("yyyy.MM.dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("user.login_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar("date", dinfo);
p.setLoop("admin_yn_list", Malgn.arr2loop(userLogin.adminYnList));
p.setLoop("login_type_list", Malgn.arr2loop(userLogin.loginTypeList));

p.display();

%>