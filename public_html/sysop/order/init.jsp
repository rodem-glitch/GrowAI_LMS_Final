<%@ include file="../init.jsp" %><%

String ch = m.rs("ch", "sysop");

p.setVar("pop_block", "pop".equals(ch) || "poplayer".equals(ch));

%>