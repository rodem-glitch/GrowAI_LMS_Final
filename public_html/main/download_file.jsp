<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//기본키
String file = m.decode(m.rs("file"));
String path = m.getUploadPath(file);
if("".equals(file)) { m.jsError(_message.get("alert.common.required_key")); return; }

//제한
String ek = m.rs("ek");
if("".equals(ek) || !m.encrypt(file + m.time("yyyyMMdd")).equals(ek)) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//객체
FileLogDao fileLog = new FileLogDao(request);

//다운로드
File f1 = new File(path);
if(f1.exists()) {
	if(!fileLog.addLog(userId, fileLog.file2info(siteId, f1, file))) { }
	m.download(path, file, 500);
} else {
	m.jsError(_message.get("alert.common.nofile"));
	return;
}

%>