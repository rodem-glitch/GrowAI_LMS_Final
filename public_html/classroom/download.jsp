<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//갱신
ClFileDao file = new ClFileDao();
FileLogDao fileLog = new FileLogDao(request);

//기본키
String ek = m.rs("ek");
int id = m.ri("id");
if(id == 0 || "".equals(ek)) { m.jsError(_message.get("alert.common.required_key")); return; }

//제한
if("".equals(ek) || !m.encrypt(id + m.time("yyyyMMdd")).equals(ek)) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//정보
DataSet info = file.find("id = " + id + "");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
String path = m.getUploadPath(info.s("filename"));

file.updateDownloadCount(id);

//다운로드
File f1 = new File(path);
if(f1.exists()) {
	if(!fileLog.addLog(userId, fileLog.file2info(siteId, f1, info.s("filename")))) { }
	m.download(path, info.s("filename"), 500);
} else {
	m.jsError(_message.get("alert.common.nofile"));
	return;
}

%>