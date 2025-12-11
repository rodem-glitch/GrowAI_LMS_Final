<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String dir = m.rs("dir");
String file = m.rs("file");

//목록
FTPClient ftp = new FTPClient();
try {
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


	String path = siteinfo.s("doc_root") + dir + "/" + file;
	File f1 = new File(path);
	if(!f1.exists()) f1 = new File(m.replace(path, "/public_html", ""));
	if(!f1.exists()) { out.print("해당 파일이 없습니다."); ftp.disconnect(); return; }

	//boolean ret = file.indexOf(".") != -1 ? ftp.deleteFile(file) : ftp.removeDirectory(file);
	boolean ret = !f1.isDirectory() ? ftp.deleteFile(file) : ftp.removeDirectory(file);
	out.print(ret
		? "success"
		: (!f1.isDirectory()
			? "파일 삭제 실패 (" + ftp.getReplyCode() + ")"
			: "폴더 삭제 실패 (" + ftp.getReplyCode() + ")\n폴더에 파일이 있는지 확인해주세요. (숨김파일 포함)"
		)
	);

	if(ftp.isConnected()) {
		ftp.logout();
		ftp.disconnect();
	}

} catch(IOException e) {
	m.log("ftp", e.toString());
	out.print("파일 삭제시 오류가 발생했습니다. " + e.toString());
} catch(Exception e) {
	m.log("ftp", e.toString());
	out.print("파일 삭제시 오류가 발생했습니다. " + e.toString());
}

%>