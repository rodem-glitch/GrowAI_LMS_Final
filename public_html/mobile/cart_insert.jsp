<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(0 == userId) { m.redirect("login.jsp"); return; }

//폼입력
String idx = m.rs("idx").replaceAll("[^0-9,]", "");

//기본키
String type = m.rs("type");
int id = m.ri("id");
if("".equals(type) || id == 0) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//변수
String[] bookList = !"".equals(idx) ? idx.split("\\,") : new String[] { };
String url = "../order/cart_common_insert.jsp?type=" + type + "&item=course," + id + ",1" + (0 < bookList.length ? "|book," + m.join(",1|book,", bookList) + ",1" : "");

//이동
m.redirect(url);

%>