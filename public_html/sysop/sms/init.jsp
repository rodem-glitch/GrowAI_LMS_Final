<%@ include file="../init.jsp" %><%

String ch = "sysop";

//객체
SmsDao sms = new SmsDao(siteId);
boolean isSend = siteinfo.b("sms_yn");
if(isSend) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

p.setVar("is_send", isSend);

%>