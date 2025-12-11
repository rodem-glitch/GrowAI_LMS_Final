<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.json.*" %><%@ include file="init.jsp" %><%

//객체
OAuthClient oauth = new OAuthClient(request, session);

//캐쉬삭제
Config.reload();

//타사아이디연동정보삭제
String[] oauths = !"".equals(siteinfo.s("oauth_vendor")) ? m.split("|", siteinfo.s("oauth_vendor")) : new String[0];
DataSet olist = m.arr2loop(oauths);
while(olist.next()) oauth.remove(olist.s("name"));

JSONObject obj = new JSONObject();
obj.put("message", "SUCCESS");
obj.put("domain", siteinfo.s("domain"));
obj.put("id", siteinfo.s("id"));

out.write(f.get("callback") + "(" + obj.toString() + ")");

%>