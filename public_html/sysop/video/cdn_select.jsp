<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.apache.commons.net.ftp.*" %>
<%@ page import="java.io.IOException" %>
<%@ include file="init.jsp" %><%

if("".equals(siteinfo.s("cdn_ftp"))) {
	m.js("window.close()");
	return;
}

//접근권한
if(!Menu.accessible(69, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

String dir = m.rs("dir", "");
String[] arr = m.split("|", siteinfo.s("cdn_ftp"));

if("C".equals(userKind) && !dir.startsWith("/" + userId)) dir = "/" + userId;

FTPClient ftp = new FTPClient();

DataSet list = new DataSet();
try {
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

	FTPFile[] files = ftp.listFiles(dir);
	for (int i = 0; i < files.length; i++) {
		list.addRow();
		list.put("path", dir + "/" + files[i].getName());
		list.put("name", files[i].getName());
		list.put("ext", m.getFileExt(files[i].getName()));
		list.put("title", list.s("name").replace("." + list.s("ext"), ""));
		list.put("size", m.getFileSize(files[i].getSize()));
		list.put("reg_date", m.time("yyyy-MM-dd HH:mm", files[i].getTimestamp().getTime()));
		list.put("is_folder", files[i].isDirectory());
		list.put("is_mp4", "mp4".equals(list.s("ext")));
		list.put("type", files[i].isDirectory() ? "폴더" : "파일");
	}
	
	if(ftp.isConnected()) {
		ftp.logout();
		ftp.disconnect();
	}
} catch(IOException ioe) {
	m.jsAlert("CDN에 접속하는 중 오류가 발생했습니다.");
	m.log("ftp", ioe.toString());
	return;
} catch(Exception e) {
	m.jsAlert("CDN에 접속하는 중 오류가 발생했습니다.");
	m.log("ftp", e.toString());
	return;
}

//출력
p.setBody("video.cdn_select");
p.setVar("query", m.qs());
p.setLoop("list", list);
p.setVar("form_script", f.getScript());
p.setVar("cdn_url", siteinfo.s("cdn_url"));
p.display();

%>