<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.regex.Pattern" %><%@ include file="init.jsp" %><%

//로그인
//if(userId != 0) { m.redirect("../main/index.jsp"); return; }

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"ktalk_"});

//객체
UserDao user = new UserDao(); user.setInsertIgnore(true);
SmsDao sms = new SmsDao(siteId);
if(siteinfo.b("sms_yn")) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));
KtalkDao ktalk = new KtalkDao(siteId); ktalk.setMalgn(m);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId); ktalkTemplate.setMalgn(m);
ktalkTemplate.d(out);

//정보
DataSet info = user.find("id = 6591 AND site_id = 1");
if(!info.next()) { }

//메일
info.put("reg_date_conv", m.time(_message.get("format.datetime.local")));
p.setVar("info", info);
p.setVar("user_nm", info.s("user_nm"));
ktalkTemplate.sendKtalk(siteinfo, info, "join", p);

%>