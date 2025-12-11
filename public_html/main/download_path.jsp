<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

String filepath = m.decode(m.rs("fp"));
String filename = m.decode(m.rs("fn"));
String ek = m.rs("ek");

//ek검사?????
if("".equals(filepath) || "".equals(filename)) {
	m.jsError(_message.get("alert.common.abnormal_access"));
	return;
}

//객체
FileLogDao fileLog = new FileLogDao(request);

//다운로드
File file = new File(filepath);
if(file.exists()) {
	if(!fileLog.addLog(userId, fileLog.file2info(siteId, file, filename))) { }
	m.download(filepath, filename, 500);
} else {
	m.jsError(_message.get("alert.common.nofile"));
	return;
}
%>