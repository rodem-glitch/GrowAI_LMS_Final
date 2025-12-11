<%@ include file="../init.jsp" %><%

String ch = m.rs("ch", "course");

p.setVar("ch", ch);

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"target_"});

%>