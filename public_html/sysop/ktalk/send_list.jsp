<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(136, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int kid = m.ri("kid");
if(kid == 0) { m.jsErrClose("기본키는 반드시 있어야 합니다."); return; }

//객체
KtalkUserDao ktalkUser = new KtalkUserDao();
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
	ktalkUser.table + " a "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id "
);
lm.setFields("a.*, b.id user_id, b.login_id, b.sms_yn, b.status");
lm.addWhere("a.ktalk_id = " + kid + "");
lm.addWhere("a.site_id = " + siteId + "");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("b.login_id, a.user_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.user_nm ASC");

//목록
DataSet list = lm.getDataSet();
while(list.next()) {
	if(list.i("user_id") == -99) list.put("user_id", "-");
	list.put("send_conv", list.b("send_yn") ? "성공" : "실패");
	list.put("mobile_conv", "-");
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? SimpleAES.decrypt(list.s("mobile")) : "-" );
	list.put("sms_yn_conv", m.getItem(list.s("sms_yn"), user.receiveYn));

	user.maskInfo(list);
}

//기록-개인정보조회
if(list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//출력
p.setLayout("pop");
p.setBody("ktalk.send_list");
p.setVar("p_title", "수신 회원");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar",lm.getPaging());
p.setVar("list_total", lm.getTotalString());
p.display();

%>