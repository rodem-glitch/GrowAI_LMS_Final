<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(39, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int mid = m.ri("mid");
if(mid == 0) { m.jsErrClose("기본키는 반드시 있어야 합니다."); return; }

//객체
MailUserDao mailUser = new MailUserDao();
UserDao user = new UserDao(isBlindUser);

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록 생성
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 10);
lm.setTable(
	mailUser.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id "
);
lm.setFields("a.*, b.id user_id, b.login_id, b.email_yn");
lm.addWhere("a.mail_id = " + mid + "");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("b.login_id, a.user_nm, a.email", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.user_nm ASC");

//목록
DataSet list = lm.getDataSet();
while(list.next()) {
	if(list.i("user_id") == -99) list.put("user_id", "-");
	list.put("send_conv", list.b("send_yn") ? "성공" : "실패");
	list.put("email_yn_conv", m.getItem(list.s("email_yn"), user.receiveYn));

	user.maskInfo(list);

	if(0 == list.i("user_id")) {
		list.put("user_nm", "[비회원]");
	}
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "메일발송대상자(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "login_id=>회원아이디", "user_nm=>성명", "email=>이메일", "send_conv=>발송여부"});
	ex.write();
	return;
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//출력
p.setLayout("pop");
p.setBody("mail.send_list");
p.setVar("p_title", "수신자");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar",lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.display();

%>