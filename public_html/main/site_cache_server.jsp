<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.*,java.io.*,dao.*,malgnsoft.db.*,malgnsoft.util.*,java.net.InetAddress,org.json.*" %><%

//객체
Malgn m = new Malgn(request, response, out);

Form f = new Form("form1");
try { f.setRequest(request); }
catch(RuntimeException re) {
    m.errorLog("Overflow file size. - " + re.getMessage(), re);
    return;
}
catch(Exception ex) {
    m.errorLog("Overflow file size. - " + ex.getMessage(), ex);
    return;
}
//기본키
String domain = m.rs("domain");
String domain2 = m.rs("domain2");
int sid = m.ri("sid");
if(1 > sid || "".equals(domain)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//객체
SiteDao site = new SiteDao();
SiteConfigDao SiteConfig = new SiteConfigDao(sid);

//초기화
site.remove(domain);
if(!"".equals(domain2)) site.remove(domain2);
SiteConfig.remove(sid + "");

//출력
JSONObject obj = new JSONObject();
obj.put("message", "SUCCESS");
obj.put("domain", domain);
obj.put("id", sid);
obj.put("server", InetAddress.getLocalHost().getHostAddress());

out.write(f.get("callback") + "(" + obj.toString() + ")");

%>