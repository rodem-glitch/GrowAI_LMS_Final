<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int manualId = m.ri("mid");

//객체
ManualDao manual = new ManualDao();

//변수
String InitPage = !"".equals(m.getCookie("MPREPAGE")) ? m.getCookie("MPREPAGE") : "../manual/main.jsp";
if(0 < manualId) InitPage = "../manual/view.jsp?id=" + manualId;

%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><%= winTitle %> - 메뉴얼</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge" />
</head>

<frameset id="_TFRM" rows="59,*" frameborder="no" border="0">
    <frame src="../manual/top.jsp" name="_Top" marginwidth="0" marginheight="0" scrolling="no" frameborder="no" border="0" noresize>
    <frameset id="_MFRM" cols="250,7,*" frameborder="no" border="0">
		<frame src="../manual/list.jsp" name="_CS" marginwidth="0" marginheight="0" scrolling="auto" frameborder="no" border="0" noresize>
		<frame src="../main/slider.jsp?width=250" name="_Slider" scrolling="no" marginwidth="0" marginheight="0" frameborder="no" border="0" noresize>
		<frame src="<%= InitPage %>" name="_BODY" id="_BODY" marginwidth="0" marginheight="0" scrolling="auto" frameborder="no" border="0">
	</frameset>
</frameset>

</html>