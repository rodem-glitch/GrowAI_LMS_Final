<%@ include file="../init.jsp" %><%

String ch = "sysop";

//객체
KtalkDao ktalk = new KtalkDao();
boolean isSend = "Y".equals(SiteConfig.s("ktalk_yn"));
if(isSend) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), SiteConfig.s("ktalk_sender_key"));
p.setVar("is_send", isSend);

//변수
int icnt = 10;

%>