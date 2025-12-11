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
	DataSet winfo = webpage.find("code = ? AND site_id = " + siteId + " AND status = 1", new String[] { m.rs("code") });
	if(!winfo.next()) { m.jsError(_message.get("alert.common.abnormal_access")); return; }
	if("preview".equals(mode)) winfo.put("content", winfo.s("content_save").replaceAll(" on([^\\t\\n\\f\\- \\/>\"'=]+\\s*)=", " on-$1="));
//	winfo.put("content", winfo.s("content").replaceAll(allowRegexr, "&lt;$1$2&gt;"));
	winfo.put("content", winfo.s("content").replaceAll(" on([^\\t\\n\\f\\- \\/>\"'=]+\\s*)=", " on-$1="));

	p.setLayout(m.rs("ch", winfo.s("layout")));
	p.setBody("main.page");
	p.setVar("p_title", winfo.s("webpage_nm"));
	p.setVar(winfo);

} else {
	//변수
	String[] splits = m.rs("pid").split("\\.");
	if(splits.length != 2) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

	//제한
	File file1 = new File(tplRoot + "/layout/layout_" + splits[0] + ".html");
	if(!file1.exists()) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

	File file2 = new File(tplRoot + "/page/" + splits[1] + ".html");
	if(!file2.exists()) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

	//출력
	p.setLayout(splits[0]);
	p.setBody("page." + splits[1]);
	//p.setVar(m.getItem(splits[0], gnbs), "on");
	//p.setVar("LNB_" + splits[1].toUpperCase(), "select");
}

p.display();

%>