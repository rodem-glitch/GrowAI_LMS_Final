<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"
    
    import="java.net.URLEncoder"

%><%@ include file="../include/sso_entry.jsp" 
%><%

/*
sso_entry.jsp 를 통해 SSO 로그인 여부를 확인한 후,
SSO 인증이 된 사용자의 경우 sp_const.jsp 에 정의된 LOGINUSER_REDIRECT_URL
그렇지 않은 사용자의 경우  ANONYMOUS_REDIRECT_URL 로 queryString 과 함께 리다이렉트시킨다.
*/

StringBuffer relayState = new StringBuffer();
String queryStr = request.getQueryString();

if(SSO_SESSION_ANONYMOUSE.equals(eXSignOnUserId)) {
	relayState.append(ANONYMOUS_REDIRECT_URL);
} else {
	relayState.append(LOGINUSER_REDIRECT_URL);
}

if(queryStr != null && !"".equals(queryStr.trim())) {
	relayState.append("?");
	relayState.append(queryStr);
}

response.sendRedirect(relayState.toString());
return;

%>