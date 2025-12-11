<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//기본키
String ek = m.rs("ek");
if("".equals(ek) || !m.encrypt(m.rs("id")).equals(ek)) { m.jsError("올바른 접근이 아닙니다."); return; }

//객체
FileDao file = new FileDao();
FileLogDao fileLog = new FileLogDao(request);

//정보
DataSet info = file.find("id = " + id + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
String path = m.getUploadPath(info.s("filename"));
info.put("filepath", path);

file.updateDownloadCount(m.ri("id"));

//다운로드
File f1 = new File(path);
if(f1.exists()) {
	if(!fileLog.addLog(userId, info)) { }
	m.download(path, info.s("filename"));
} else {
	m.jsError("파일이 존재하지 않습니다.");
	return;
}

%>