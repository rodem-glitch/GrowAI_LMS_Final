<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.regex.Pattern" %><%@ include file="init.jsp" %><%

String key = "7B1F83A608723CEDDFA9AED338FC796C";

if(!"direct".equals(mSession.s("login_method"))) {
	int ut = m.getUnixTime();
	String ek = m.encrypt(ut + "|" + loginId + "|" + key, "SHA-256");
	m.jsReplace("modify.jsp?ek=" + ek + "&ut=" + ut, "parent");
}

//폼체크
f.addElement("passwd", null, "hname:'비밀번호', required:'Y'");

//확인
if(m.isPost() && f.validate()) {
	
	String passwd = m.encrypt(f.get("passwd"), "SHA-256");
	if(!passwd.equals(uinfo.s("passwd"))) {
		m.jsAlert(_message.get("alert.member.reenter_password"));
		return;
	}

	//이동
	int ut = m.getUnixTime();
	String ek = m.encrypt(ut + "|" + loginId + "|" + key, "SHA-256");
	m.jsReplace("modify.jsp?ek=" + ek + "&ut=" + ut, "parent");
	return;
}

//출력
p.setLayout("mypage_newmain");
p.setBody("mypage.modify_verify");
p.setVar("form_script", f.getScript());

// 헤더용 변수 설정
p.setVar("login_block", true);
p.setVar("SYS_USERNAME", uinfo.s("user_nm"));
String userNameForHeader = uinfo.s("user_nm");
p.setVar("SYS_USERNAME_INITIAL", userNameForHeader.length() > 0 ? userNameForHeader.substring(0, 1) : "?");

p.display();

%>