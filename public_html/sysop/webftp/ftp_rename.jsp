<%@ page import="java.io.UnsupportedEncodingException" %>
<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String dir = m.rs("dir");
String file = m.rs("file");
String name = m.rs("name");

//목록
FTPClient ftp = new FTPClient();
try{
	ftp.setControlEncoding("utf-8");
	ftp.connect(ftpHost, ftpPort);
	ftp.enterLocalPassiveMode();

	int loginResult = loginValidate(ftp, m, ftpId, ftpPw);
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

	boolean ret = ftp.rename(file, name);

	out.print(ret ? "success" : "파일명 변경 실패");

	if(ftp.isConnected()) {
		ftp.logout();
		ftp.disconnect();
	}
} catch(UnsupportedEncodingException uee) {
	m.log("ftp", uee.toString());
	out.print("파일명 변경시 오류가 발생했습니다. " + uee.toString());
} catch(Exception e) {
	m.log("ftp", e.toString());
	out.print("파일명 변경시 오류가 발생했습니다. " + e.toString());
}
	
%>