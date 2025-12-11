<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if("".equals(uinfo.s("email"))) {
	m.jsError("프로젝트 게시판 연동은 이메일 계정이 반드시 필요합니다.");
	return;
}

DataSet info = Config.getDataSet("//config/privateKey/ppm");
info.next();

String ssoUrl =  "http://begas.mproject.co.kr/main/slogin.jsp";
String ekey = info.s("ekey");
String today = m.time("yyyyMMdd");
String name = SimpleAES.encrypt(userName, ekey);
String email = SimpleAES.encrypt(uinfo.s("email"), ekey);
String mobile = SimpleAES.encrypt(SimpleAES.decrypt(uinfo.s("mobile")), ekey);
String company = SimpleAES.encrypt(uinfo.s("etc1"), ekey);
String ek = m.sha256(email + ekey + today);

%>
<body onload="document.forms['form1'].submit();">
<form name="form1" method="POST" action="<%= ssoUrl %>">
<input type="hidden" name="ek" value="<%= ek %>">
<input type="hidden" name="email" value="<%= email %>">
<input type="hidden" name="name" value="<%= name %>">
<input type="hidden" name="mobile" value="<%= mobile %>">
<input type="hidden" name="company" value="<%= company %>">
</form>