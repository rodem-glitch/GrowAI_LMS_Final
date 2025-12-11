<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(41, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int mid = m.ri("mid");
if(mid == 0) { m.jsErrClose("기본키는 반드시 있어야 합니다."); return; }

//객체
MessageUserDao messageUser = new MessageUserDao();
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
	messageUser.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id "
);
lm.setFields("a.*, b.user_nm, b.login_id");
lm.addWhere("a.message_id = " + mid + "");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("b.login_id, b.user_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "b.user_nm ASC");

//목록
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("read_conv", list.b("read_yn") ? "수신" : "미수신");
	list.put("read_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("read_date")));
	user.maskInfo(list);
}

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "쪽지대상자(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "user_nm=>성명", "login_id=>회원아이디", "email=>이메일", "read_conv=>수신여부", "read_date_conv=>수신일"}, "쪽지대상자(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setLayout("pop");
p.setBody("message.send_list");
p.setVar("p_title", "수신자");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar",lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.display();

%>