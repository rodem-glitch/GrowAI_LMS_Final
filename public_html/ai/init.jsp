<%@ include file="../init.jsp" %><%

String ch = m.rs("ch", "blank");

//제한-사이트 AI 이용
if(!"Y".equals(SiteConfig.s("sys_ai_chat_yn"))) { m.jsAlert(_message.get("alert.common.abnormal_access")); return; } //권한추가

%>