<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><%= winTitle %></title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge" />
<% if(isDevServer) { %><link rel="shortcut icon" href="/sysop/favicon_devsysop.ico" />
<% } else { %><link rel="shortcut icon" href="/sysop/favicon_servicesysop.ico" /><% } %>
</head>

<!-- <frameset id="_MFRM" cols="300,7,*" frameborder="no" border="0"> -->
<frameset id="_MFRM" cols="300,*" frameborder="no" border="0">
	<frame src="../crm/memo_list.jsp?uid=<%=uid%>" name="_CS" marginwidth="0" marginheight="0" scrolling="auto" frameborder="no" border="0" noresize>
	<!-- <frame src="../main/slider.jsp?width=300" name="_Slider" scrolling="no" marginwidth="0" marginheight="0" frameborder="no" border="0" noresize> -->
	<frame src="../crm/main.jsp?uid=<%=uid%>" name="_BODY" id="_BODY" marginwidth="0" marginheight="0" scrolling="auto" frameborder="no" border="0">
</frameset>
</html>