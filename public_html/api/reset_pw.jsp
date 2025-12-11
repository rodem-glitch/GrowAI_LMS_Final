<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

f.addElement("pw", null, "hname:'변경암호', allowhtml:'Y'");

//변수
String pw = Malgn.urldecode(f.get("pw"));
if("".equals(pw) || !userIp.startsWith("10.")) return;
System.out.println(pw);

Site.execute("UPDATE " + Site.table + " SET ftp_pw = ? WHERE id = 1", new String[] { pw });
Site.clear();
Site.remove(siteinfo.s("domain"));
SiteConfig.clear();

%>