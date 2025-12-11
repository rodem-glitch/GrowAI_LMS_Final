<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { m.jsAlert(_message.get("alert.member.required_login")); return; }

//기본키
String type = m.rs("type");
String idx = m.rs("idx").replaceAll("[^0-9,]", "");;
String bidx = m.rs("bidx").replaceAll("[^0-9,]", "");;
if("".equals(type) || ("".equals(idx) && "".equals(bidx))) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//변수
String[] courseList = !"".equals(idx) ? idx.split("\\,") : new String[] { };
String[] bookList = !"".equals(bidx) ? bidx.split("\\,") : new String[] { };
String url = "../order/cart_common_insert.jsp?type=" + type + "&item=" + (0 < courseList.length ? "|course," + m.join(",1|course,", courseList) + ",1" : "") + (0 < bookList.length ? "|book," + m.join(",1|book,", bookList) + ",1" : "");
url = m.replace(url, "=|", "=");

//이동
m.redirect(url);

%>