<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String mode = m.rs("mode");
boolean pidBlock = !"".equals(m.rs("pid"));
boolean codeBlock = !"".equals(m.rs("code"));
if(!pidBlock && !codeBlock) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

if(codeBlock) {
	//객체
	WebpageDao webpage = new WebpageDao();

	//정보
	DataSet winfo = webpage.find("code = '" + m.rs("code") + "' AND site_id = " + siteId + " AND status = 1");
	if(!winfo.next()) { m.jsError(_message.get("alert.common.abnormal_access")); return; }
	if("preview".equals(mode)) winfo.put("content", winfo.s("content_save"));

	p.setLayout(ch);
	p.setBody("mobile.page");
	p.setVar(winfo);

} else {
	//변수
	String pid = m.rs("pid");
	if("".equals(pid)) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

	//제한
	File file2 = new File(tplRoot + "/page/" + pid + ".html");
	if(!file2.exists()) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

	//출력
	p.setLayout(ch);
	p.setBody("page." + pid);
	//p.setVar(m.getItem(splits[0], gnbs), "on");
	//p.setVar("LNB_" + splits[1].toUpperCase(), "select");
}

p.display();

%>