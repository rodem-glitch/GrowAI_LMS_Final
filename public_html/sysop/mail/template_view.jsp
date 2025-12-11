<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String t = m.rs("t");
if("".equals(t)) return;

//객체
MailTemplateDao mailTemplate = new MailTemplateDao();

//출력
out.print(mailTemplate.getTemplate(siteId, t));

%>