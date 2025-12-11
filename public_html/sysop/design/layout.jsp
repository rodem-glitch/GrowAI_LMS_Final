<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init_layout.jsp" %><%

if("layout".equals(mode)) {
	layouts.next();
	m.redirect("layout_modify.jsp?mode=" + mode + "&dir=layout&pnm=" + layouts.s("id"));
	return;
} else if("css".equals(mode)) {
	m.redirect("layout_modify.jsp?mode=" + mode + "&dir=css&pnm=" + m.split("=>", cssArr[0], 2)[0]);
	return;
}

%>