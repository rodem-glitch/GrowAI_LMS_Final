<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.apache.commons.net.ftp.*" %>
<%@ page import="java.io.UnsupportedEncodingException" %>
<%@ include file="init.jsp" %><%

if("".equals(siteinfo.s("cdn_ftp"))) {
	out.print("FTP 정보가 없습니다.");
	return;
}

String dir = m.rs("dir");
String file = m.rs("file");
String[] arr = m.split("|", siteinfo.s("cdn_ftp"));

//목록
FTPClient ftp = new FTPClient();
try{
	ftp.setControlEncoding("utf-8");
	ftp.connect(arr[0]);
	ftp.enterLocalPassiveMode();
	
	int loginResult = loginValidate(ftp, m, arr[1], arr[2]);
	if(-1 == loginResult) {
		ftp.disconnect();
		m.jsError("FTP 접속시도가 너무 많습니다. 잠시 후 다시 시도하세요.");
		return;
	} else if (-2 == loginResult) {
		ftp.disconnect();
		m.jsError("FTP 접속정보가 일치하지 않습니다. 관리자에게 문의하세요.");
		return;
	}

	if(!"".equals(dir)) ftp.changeWorkingDirectory(dir);

	boolean ret = file.indexOf(".") != -1 ? ftp.deleteFile(file) : ftp.removeDirectory(file);

	out.print(ret ? "success" : "파일 삭제 실패");

	if(ftp.isConnected()) {
		ftp.logout();
		ftp.disconnect();
	}
} catch(UnsupportedEncodingException uee) {
	m.log("ftp", uee.toString());
	out.print("파일 삭제시 오류가 발생했습니다. " + uee.toString());
} catch(Exception e) {
	m.log("ftp", e.toString());
	out.print("파일 삭제시 오류가 발생했습니다. " + e.toString());
}

%>