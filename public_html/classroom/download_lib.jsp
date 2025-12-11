<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//객체
LibraryDao library = new LibraryDao();
FileLogDao fileLog = new FileLogDao(request);

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//제한
String ek = m.rs("ek");
if("".equals(ek) || !m.encrypt(id + m.time("yyyyMMdd")).equals(ek)) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//정보
DataSet info = library.find("id = " + id + "");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

String path = m.getUploadPath(info.s("library_file"));
library.updateDownloadCount(id);

//다운로드
File f1 = new File(path);
if(f1.exists()) {
	if(!fileLog.addLog(userId, fileLog.file2info(siteId, f1, info.s("library_file")))) { }
	m.download(path, info.s("library_file"), 500);
} else {
	m.jsError(_message.get("alert.common.nofile"));
	return;
}

%>