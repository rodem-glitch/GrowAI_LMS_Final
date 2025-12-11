<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserMemoDao userMemo = new UserMemoDao();
//UserDeptDao userDept = new UserDeptDao();

//변수
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");

//처리
if("hide".equals(m.rs("mode"))) {
	DataSet uminfo = userMemo.find("id = ? AND user_id = ? AND status != -1", new Object[] { m.ri("umid"), uid });
	if(!uminfo.next()) { m.jsAlert("해당 메모가 없습니다."); return; }

	userMemo.item("status", 0);
	if(!userMemo.update("id = " + m.ri("umid") + " AND user_id = " + uid)) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("memo_list.jsp?" + m.qs("mode,umid"), "parent");

} else if("show".equals(m.rs("mode"))) {
	DataSet uminfo = userMemo.find("id = ? AND user_id = ? AND status != -1", new Object[] { m.ri("umid"), uid });
	if(!uminfo.next()) { m.jsAlert("해당 메모가 없습니다."); return; }

	userMemo.item("status", 1);
	if(!userMemo.update("id = " + m.ri("umid") + " AND user_id = " + uid)) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("memo_list.jsp?" + m.qs("mode,umid"), "parent");

}

//정보
DataSet info = user.find("id = " + uid + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) {
	m.jsError("해당 정보가 없습니다.");
	m.js("parent.window.close();");
	return;
}
String mobile = "";
mobile = !"".equals(info.s("mobile")) ? info.s("mobile") : "-";
info.put("status_conv", m.getItem(info.s("status"), user.statusList));
info.put("mobile", mobile);
info.put("login_block", "U".equals(info.s("user_kind")));
info.put("admin_block", !"U".equals(info.s("user_kind")));
info.put("ek", m.encrypt(info.s("login_id") + "_" + m.time("yyyyMMdd") + "_LMSLOGIN2014", "SHA-256"));
info.put("ek_sysop", m.md5("SEK" + uid + today));
if(0 < info.i("dept_id")) {	
	info.put("dept_nm_conv", userDept.getNames(info.i("dept_id")));
} else {	
	info.put("dept_nm", "[미소속]");
	info.put("dept_nm_conv", "[미소속]");
}
user.maskInfo(info);

//기록-개인정보조회
if("".equals(m.rs("mode")) && info.size() > 0 && !isBlindUser) _log.add("V", "회원조회", info.size(), "이러닝 운영", info);

//폼체크
f.addElement("memo", null, "hname:'상담내용', required:'Y'");

Form f2 = new Form("form2");
try { f2.setRequest(request); }
catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage()); return; }
catch(Exception ex) { m.errorLog("Overflow file size. - " + ex.getMessage()); return; }
f2.addElement("s_hide", null, null);

//등록
if(m.isPost() && f.validate()) {

	userMemo.item("site_id", siteId);
	userMemo.item("user_id", uid);
	userMemo.item("memo", f.get("memo"));
	userMemo.item("manager_id", userId);
	userMemo.item("reg_date", now);
	userMemo.item("status", 1);
	if(!userMemo.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("memo_list.jsp?" + m.qs(), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum(5);
lm.setNaviNum(5);
lm.setTable(
	userMemo.table + " a "
	+ " LEFT JOIN " + user.table + " m ON a.manager_id = m.id "
);
lm.setFields("a.*, m.user_nm manager_nm");
lm.addWhere("a.user_id = " + uid + "");
lm.addWhere("a.status != -1");
if(!"Y".equals(m.rs("s_hide"))) lm.addWhere("a.status != 0");
lm.setOrderBy("a.reg_date DESC, a.id DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv",
		0 == m.diffDate("D", m.time("yyyyMMdd", list.s("reg_date")), today)
		? m.time("HH:mm", list.s("reg_date"))
		: m.time("yyyy.MM.dd HH:mm", list.s("reg_date"))
	);
	list.put("memo_conv", m.nl2br(list.s("memo")));
}

//출력
p.setLayout("blank");
p.setBody("crm.memo_list");
p.setVar("form_script", f.getScript());
p.setVar("form2_script", f2.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("mode_query", m.qs("mode,umid"));

p.setVar(info);

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.setVar("list_num_conv", m.nf(lm.getTotalNum()));

p.display();

%>