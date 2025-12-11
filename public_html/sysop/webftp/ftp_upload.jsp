<%@ page import="java.io.IOException" %>
<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String dir = m.rs("dir");
String parentDir = (!"".equals(dir) ? dir.substring(0, dir.lastIndexOf("/")) : "");

f.uploadDir = Config.getDataDir() + "/ftp";
f.denyExt(new String[] {"jsp", "jspx", "php", "asp", "aspx"});
File attFile = f.saveFile("filename");
if(attFile != null) {

	//목록
	FTPClient ftp = new FTPClient();
	try {
		ftp.setControlEncoding("utf-8");
		ftp.connect(ftpHost, ftpPort);
		ftp.enterLocalPassiveMode();

		int loginResult = loginValidate(ftp, m, ftpId, ftpPw);
		if(-1 == loginResult) {
			m.jsError("FTP 접속시도가 너무 많습니다. 잠시 후 다시 시도하세요.");
			return;
		} else if (-2 == loginResult) {
			m.jsError("FTP 접속정보가 일치하지 않습니다. 관리자에게 문의하세요.");
			return;
		}

		if(!"".equals(dir)) ftp.changeWorkingDirectory(dir);

		ftp.setFileType(FTP.BINARY_FILE_TYPE);

		FileInputStream fis = new FileInputStream(attFile);
		ftp.storeFile(m.replace(f.getFileName("filename"), " ", "_"), fis);
		
	} catch(IOException ioe) {
		out.print("{\"success\":false, \"error\":\"파일을 업로드 하는 중 오류가 발생했습니다.\", \"reset\":true}");
		m.log("ftp", ioe.toString());
		return;
	} catch(Exception e) {
		out.print("{\"success\":false, \"error\":\"파일을 업로드 하는 중 오류가 발생했습니다.\", \"reset\":true}");
		m.log("ftp", e.toString());
		return;
	} finally {
		ftp.logout();
		ftp.disconnect();
	}

	attFile.delete();
	out.print("{\"success\":true}");
	return;
}

//제한 확장자
String limitExt = "|exe|jsp|asp|aspx|php|php3";
String limitExtConv = "";
limitExt = !"".equals(limitExt)? m.replace(limitExt.substring(1), "|", ";") : "";
if(!"".equals(limitExt)) {
	limitExtConv = m.replace(limitExt, ";", ", ");
	limitExt += ";" + limitExt.toUpperCase();
}

//출력
p.setRoot(Config.getDocRoot() + "/sysop/html");
p.setLayout("poplayer");
p.setBody("webftp.ftp_upload");
p.setVar("p_title", "파일 업로드");
p.setVar("query", m.qs());
p.setVar("max_file_size", Config.getInt("maxPostSize") * 1024);
p.setVar("limit_block", !"".equals(limitExt));
p.setVar("limit_ext", limitExt);
p.setVar("limit_ext_conv", limitExtConv);
p.display();

%>