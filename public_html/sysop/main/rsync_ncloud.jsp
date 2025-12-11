<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

if(!superBlock) m.jsReplace("/common/error_404.html");

String ret = "";
String path = m.rs("path");

ret = m.exec("/Users/kyounghokim/IdeaProjects/MalgnLMS/rsync.sh " + path);
m.p(m.nl2br(ret));

%>