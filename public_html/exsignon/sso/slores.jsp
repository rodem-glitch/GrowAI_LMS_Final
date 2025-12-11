<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"

%><%@ include file="../common/sso_common.jsp" 
%><%

/*
통합 로그아웃 요청 이후 relayState 값이 존재한다면 해당 URL로,
존재하지 않는다면 context root로 리다이렉트한다.
*/

String relayState = request.getParameter(RELAY_STATE_NAME);
if(relayState == null || "".equals(relayState.trim())) {
    relayState = this.addContextPath(request, "/");
}

response.sendRedirect(relayState);

return;

%>