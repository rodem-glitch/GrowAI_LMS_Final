<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"

%><%@ include file="../common/sso_common.jsp"
%><%	

	String userId = request.getParameter(NAMEID_NAME);
	String targetSp = request.getParameter(TARGET_ID_NAME);
	String relayState = request.getParameter(RELAY_STATE_NAME);
	String rememberMe = request.getParameter(SSO_REMEMBERME);
	
	HttpSession session = request.getSession();
	session.setAttribute("eXSignOn.assert.userid", userId);

%><!DOCTYPE html><html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<script>
	window.onload=function(){
		
		document.getElementById('assertLoginFrm').submit();
		
	}
</script>
</head>
<body>
<form id="assertLoginFrm" name="assertLoginFrm" method="post" action="../sso/sso_assert.jsp">
  <input type="hidden" name="<%= SSO_REMEMBERME %>" value="<%= rememberMe %>" />
  <input type="hidden" name="<%= TARGET_ID_NAME %>" value="<%= targetSp %>" />
  <input type="hidden" name="<%= RELAY_STATE_NAME %>" value="<%= relayState %>" />
</form>
</body>
</html>