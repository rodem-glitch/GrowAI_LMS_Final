<%@ include file="../init.jsp" %><%

String ch = "sysop";

p.setVar("auth_course_block", Menu.accessible(33, userId, userKind, false));
p.setVar("auth_management_block", Menu.accessible(75, userId, userKind, false));
p.setVar("auth_complete_block", Menu.accessible(76, userId, userKind, false));
p.setVar("auth_auto_block", Menu.accessible(42, userId, userKind, false));

%>