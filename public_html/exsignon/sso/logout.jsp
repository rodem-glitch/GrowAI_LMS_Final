<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"

%><%@ include file="../common/sso_common.jsp" 
%><%@ include file="../common/sp_const.jsp"
%><%

/*
SSO 통합로그아웃을 요청하는 파일로, 이것이 호출되면 해당 사용자의 인증서버 세션을 만료시키기 위한 요청을 보낸다.
*/

String relayState = request.getParameter(RELAY_STATE_NAME);

if(relayState == null) {
    relayState = "";
}

HttpSession session = request.getSession();
session.invalidate();

%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<script type="text/javascript">
function logout() {
  document.logoutFrm.submit();  
}

</script>
</head>
<body onload="logout()">
  <form id="logoutFrm" name="logoutFrm" action="<%= this.generateUrl(IDP_URL, LOGOUT_URL) %>" method="post">
    <input type="hidden" name="<%= ID_NAME %>" value="<%= SP_ID %>" />
    <input type="hidden" name="<%= RELAY_STATE_NAME %>" value="<%= relayState %>" />
  </form>
</body>
</html>