<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.*,java.io.*,dao.*,malgnsoft.db.*,malgnsoft.util.*,java.net.InetAddress,org.json.*" %><%

//객체
Malgn m = new Malgn(request, response, out);

Form f = new Form("form1");
try { f.setRequest(request); }
catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage()); return; }
catch(Exception ex) { m.errorLog("Exception : Overflow file size. - " + ex.getMessage()); return; }

//제한-IP
if(!"115.91.52.203".equals(request.getRemoteAddr())  && !"115.91.52.204".equals(request.getRemoteAddr() )&& !"106.248.195.135".equals(request.getRemoteAddr())) {
	return;
}

//변수
StringBuffer sb = new StringBuffer();
boolean isError = false;

//기본키
int sid = m.ri("sid");
String key = m.rs("k");
String ek = m.rs("ek");
if(1 > sid) { sb.append("올바른 접근이 아닙니다. [1]"); isError = true; }
if(!isError && !ek.equals(m.encrypt("SSL_SETTING_" + key + "_PCC_" + m.time("yyyyMMdd")))) { sb.append("올바른 접근이 아닙니다. [2]"); isError = true; }

//제한-POST
//if(!isError && !m.isPost()) { sb.append("올바른 접근이 아닙니다. [3]"); isError = true; }

//객체
SiteDao site = new SiteDao();

//정보
DataSet info = null;
if(!isError) {
	info = site.find("id = " + sid);
	if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); isError = true; }
}

//처리
if(!isError) {
	String path = "/root/setup_ssl.sh " + info.s("ftp_id");

	InetAddress addr = InetAddress.getLocalHost();
	String hostname = addr.getHostName();

	sb.append(hostname + "<br>\n");
	sb.append(info.s("site_nm") + "<br>\n");

	try {
		String line;
		Process proc = Runtime.getRuntime().exec(path);
		BufferedReader input = new BufferedReader(new InputStreamReader(proc.getInputStream()));

		while((line = input.readLine()) != null) {
			sb.append(line + "<br>\n");
		}

		input.close();
	} catch(RuntimeException re) {
		sb.append(re.getMessage() + "<br>\n");
	} catch(Exception ex) {
		sb.append(ex.getMessage() + "<br>\n");
	}
}

//출력
JSONObject obj = new JSONObject();
obj.put("message", sb.toString());
obj.put("domain", "214.malgnlms.com");
obj.put("success", !isError);
//obj.put("domain", siteinfo.s("domain"));
//obj.put("id", siteinfo.s("id"));

out.print(f.get("callback") + "(" + obj.toString() + ")");

%>