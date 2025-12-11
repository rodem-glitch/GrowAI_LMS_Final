<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.json.*" %><%@ include file="init.jsp" %><%

//객체
SiteDao site = new SiteDao();

//폼입력
String mode = m.rs("mode");
String sid = m.rs("sid");

//캐시삭제
if("all".equals(mode)) {
	Site.clear();
	SiteConfig.clear();

} else {	
	if(!"".equals(sid)) {
		//정보
		DataSet sinfo = site.find("id = ? AND status != -1", new String[] {sid});
		if(!sinfo.next()) return;
		siteinfo = sinfo;
	}

	Site.remove(siteinfo.s("domain"));
	if(!"".equals(siteinfo.s("domain2"))) Site.remove(siteinfo.s("domain2"));

	SiteConfig.remove(siteinfo.s("id"));

}

//출력
JSONObject obj = new JSONObject();
obj.put("message", "SUCCESS");
obj.put("domain", siteinfo.s("domain"));
obj.put("id", siteinfo.s("id"));

out.write(f.get("callback") + "(" + obj.toString() + ")");

%>