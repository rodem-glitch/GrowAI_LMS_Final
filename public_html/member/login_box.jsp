<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//SSO
if(siteinfo.b("sso_yn") && !"".equals(siteinfo.s("sso_url"))) return;

//폼입력
String id = m.reqSql("id");
String passwd = m.reqSql("passwd");

//객체
UserDao user = new UserDao();
GroupDao group = new GroupDao();

//폼체크
f.addElement("id", null, "hname:'아이디', required:'Y'");
f.addElement("passwd", null, "hname:'비밀번호', required:'Y'");

//출력
p.setLayout(null);
p.setBody("main.login_box");
p.setVar("form_script", f.getScript());

p.display();

%>