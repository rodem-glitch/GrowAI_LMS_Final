<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//객체
ClFileDao clfile = new ClFileDao();
FileLogDao fileLog = new FileLogDao(request);

//기본키
String ek = m.rs("ek");
String id = m.rs("id");
if("".equals(ek) || "".equals(id)) { m.jsError("올바른 접근이 아닙니다."); return; }
if(!m.encrypt(m.rs("id")).equals(ek)) { m.jsError("올바른 접근이 아닙니다."); return; }

//정보
DataSet info = clfile.find("id = '" + id + "'");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
String path = m.getUploadPath(info.s("filename"));

if(!"".equals(id)) clfile.updateDownloadCount(m.ri("id"));

//다운로드
File f1 = new File(path);
if(f1.exists()) {
	if(!fileLog.addLog(userId, fileLog.file2info(siteId, f1, info.s("filename")))) { }
	m.download(path, info.s("filename"));
} else {
	m.jsError("파일이 존재하지 않습니다.");
	return;
}

%>