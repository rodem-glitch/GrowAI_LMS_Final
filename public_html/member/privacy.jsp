<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
WebpageDao webpage = new WebpageDao();

//출력
p.setLayout(ch);
p.setBody(ch + ".privacy");

p.setVar("LNB_PRIVACY", "select");
p.setVar("privacy", webpage.getOne("SELECT content FROM " + webpage.table + " WHERE code = 'privacy' AND site_id = " + siteId + " AND status = 1"));
p.display();

%>