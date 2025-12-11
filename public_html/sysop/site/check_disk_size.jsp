<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

int sid = m.ri("sid");
String domain = m.rs("domain");

if(sid < 1) { out.print("유효하지 않은 파라미터"); return; }

SiteDao site = new SiteDao();
DataSet info = site.find("id = " + sid, "ftp_id");
if(!info.next()) { out.print("사이트 정보가 없습니다."); return; }

try {

	String webSize = m.exec("/usr/bin/du -hs /home/" + info.s("ftp_id"));
	String dataSize = m.exec("/usr/bin/du -hs /home/data/" + info.s("ftp_id"));

	int pos1 = webSize.indexOf("\t");
	if(pos1 > 0) webSize = webSize.substring(0, pos1);

	int pos2 = dataSize.indexOf("\t");
	if(pos2 > 0) dataSize = dataSize.substring(0, pos2);

	out.print(webSize + "|" + dataSize);

} catch(RuntimeException re) {
	m.errorLog("RuntimeException : " + re.getMessage(), re);
	out.print("세팅중 오류가 발생되었습니다.");
} catch(Exception e) {
	m.errorLog("Exception : " + e.getMessage(), e);
	out.print("세팅중 오류가 발생되었습니다.");
}

%>