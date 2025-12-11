<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"

%><%@ include file="../common/sso_common.jsp" 
%><%@ include file="../common/sp_const.jsp" 
%><%

/*
사용자 로그인이 되어 있지 않은 경우, 이 파일을 호출하면
연계시스템의 개별로그인 페이지가 아닌 인증서버에 설정된 통합로그인 페이지로 리다이렉트 시킨다.
*/

java.util.Map paramMap = new java.util.HashMap();
paramMap.put(ID_NAME, SP_ID);
paramMap.put(AC_NAME, "Y");
paramMap.put(IFA_NAME, "N");

String relayState = request.getParameter(RELAY_STATE_NAME);
if(relayState != null && !"".equals(relayState.trim())) {
    paramMap.put(RELAY_STATE_NAME, relayState);    
}

String redirectUrl = this.generateUrlWithParam(IDP_URL, AUTH_URL, paramMap);
response.sendRedirect(redirectUrl);

return;

%>