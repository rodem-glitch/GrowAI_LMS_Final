<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { m.jsAlert(_message.get("alert.member.required_login")); return; }

//기본키
String type = m.rs("type");
int id = m.ri("id");
if("".equals(type) || id == 0) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//변수
String url = "../order/cart_common_insert.jsp?type=" + type + "&item=freepass," + id + ",1";

//이동
m.redirect(url);

%>