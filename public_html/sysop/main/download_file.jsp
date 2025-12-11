<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//기본키
String file = m.decode(m.rs("file"));
String path = m.getUploadPath(file);
if("".equals(file)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//제한
String ek = m.rs("ek");
if("".equals(ek) || !m.encrypt(file + m.time("yyyyMMdd")).equals(ek)) { m.jsError("잘못된 접근입니다."); return; }

//객체
FileLogDao fileLog = new FileLogDao(request);

//다운로드
File f1 = new File(path);
if(f1.exists()) {
	if(!fileLog.addLog(userId, fileLog.file2info(siteId, f1, file))) { }
	m.download(path, file, 500);
} else {
	m.jsError("파일이 존재하지 않습니다.");
	return;
}

%>