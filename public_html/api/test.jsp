<%--
  Created by IntelliJ IDEA.
  User: kyounghokim
  Date: 2025. 11. 11.
  Time: 오후 4:17
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html; charset=utf-8" %>
<%@ include file="init.jsp" %>
<%
    Http http = new Http("http://172.28.2.41/find.jsp");
    http.setParam("table", "COM.LMS_MEMBER_VIEW");
//http.setParam("where", "member_key=300");
    http.setParam("limit", "5");
    DataSet ret = Json.decode(http.send("POST"));

    if(ret.next()) m.p(ret);
%>
