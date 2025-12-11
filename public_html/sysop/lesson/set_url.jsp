<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

out.print("<script>");
out.print("top.opener.document.forms['form1']['" + m.rs("field") + "'].value = '" + m.rs("url") + "';");
out.print("top.window.close()");
out.print("</script>");

%>