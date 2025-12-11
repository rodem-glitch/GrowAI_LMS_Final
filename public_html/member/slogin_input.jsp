<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%


if(siteId != 66) return;

out.print("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, target-densitydpi=medium-dpi\" /><style>div {word-break: break-all;}</style>");

m.p(f.data.toString());
m.p(m.reqMap("").toString());

String log = "{f.data} " + f.data.toString() + "\n\n{m.reqMap} " + m.reqMap("").toString();
m.log("slogin_input_" + siteId, log);

%>