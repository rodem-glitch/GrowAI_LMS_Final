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
<style type="text/css">
html, body { margin:0; padding:0; width:100%; height:100%; overflow:hidden; }
#_BODY { box-sizing:border-box; width:100%; height:100%; border:0 none; padding-right:300px; }
#_CS { box-sizing:border-box; position:absolute; width:300px; height:100%; top:0; right:0; z-index:99997; overflow:hidden; border:0 none; background-color:#ffffff; border-left:1px solid #503e05; }
</style>
<body>
<iframe src="../crm/course_list.jsp?uid=<%=uid%>" name="_BODY" id="_BODY" frameborder="0" border="0"></iframe>
<iframe src="../crm/memo_list.jsp?uid=<%=uid%>" name="_CS" id="_CS" scrolling="no" frameborder="0" border="0"></iframe>
</div>
</body>
</html>