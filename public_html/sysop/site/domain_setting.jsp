<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

int sid = m.ri("sid");
String domain = m.rs("domain");

if(sid < 0 || "".equals(domain)) { m.jsAlert("유효하지 않은 파라미터"); return; }

SiteDao site = new SiteDao();
DataSet info = site.find("id = " + sid, "ftp_id");
if(!info.next()) { m.jsAlert("사이트 정보가 없습니다."); return; }

if(new File("/web/" + domain).exists()) {
	m.jsAlert("이미 세팅된 도메인입니다.");
	return;
}

try {
    Process proc = Runtime.getRuntime().exec("/bin/ln -s /home/" + info.s("ftp_id") + "/public_html " + "/web/" + domain);
	if(domain.startsWith("www.")) Runtime.getRuntime().exec("/bin/ln -s /home/" + info.s("ftp_id") + "/public_html " + "/web/" + domain.replace("www.", ""));
    BufferedReader br = new BufferedReader(new InputStreamReader(proc.getInputStream()));
    String line = null;
   
    while((line = br.readLine()) != null) {
        m.jsAlert(line);
    }

	if(line == null) m.jsAlert("성공적으로 세팅되었습니다.");

} catch (RuntimeException re) {
    m.errorLog("RuntimeException : " + re.getMessage(), re);
    m.jsAlert("세팅중 오류가 발생되었습니다. 시스템 로그를 확인해주세요.");
} catch(Exception e) {
    m.errorLog("Exception : " + e.getMessage(), e);
	m.jsAlert("세팅중 오류가 발생되었습니다. 시스템 로그를 확인해주세요.");
}

%>