<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%


//출력
p.setLayout("blank");
p.setBody("user.find_right");
p.setVar("form_script", f.getScript());
p.display(out);

%>