<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int tempId = m.getRandInt(-2000000, 1990000);

//출력
p.setLayout(ch);
p.setBody("mobile.formmail");

p.setVar("temp_id", tempId);
p.setVar("allow_ext", "jpg|jpeg|gif|png|swf|mp4|flv|mov|qt|mpeg|wmv|wma|asf|mp3|avi|wmp|rmp|ra|pdf|hwp|txt|doc|docx|xls|xlsx|ppt|pptx|zip|7z|rar|alz|egg");
p.display();

%>