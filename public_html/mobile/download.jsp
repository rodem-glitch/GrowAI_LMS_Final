<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//기본키
String ek = m.rs("ek");
if("".equals(ek) || !m.encrypt(m.rs("id") + m.time("yyyyMMdd")).equals(ek)) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//객체
FileDao file = new FileDao();
FileLogDao fileLog = new FileLogDao(request);

//정보
DataSet info = file.find("id = " + id + "");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
String path = m.getUploadPath(info.s("filename"));
info.put("filepath", path);
info.put("site_id", siteId);

file.updateDownloadCount(m.ri("id"));

//다운로드
File f1 = new File(path);
if(f1.exists()) {
	if(!fileLog.addLog(userId, info)) { }
	m.download(path, info.s("filename"), 500);
} else {
	m.jsError(_message.get("alert.common.nofile"));
	return;
}

%>