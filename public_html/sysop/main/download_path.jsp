<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.*,java.io.*,dao.*,malgnsoft.db.*,malgnsoft.util.*" %><%

Malgn m = new Malgn(request, response, out);

String filepath = m.decode(m.rs("fp"));
String filename = m.decode(m.rs("fn"));
String ek = m.rs("ek");

//ek검사?????
if("".equals(filepath) || "".equals(filename)) {
	m.jsError("올바른 정보가 아닙니다..");
	return;
}

//다운로드
File file = new File(filepath);
if(file.exists()) {
	m.download(filepath, filename);
} else {
	m.jsError("파일이 존재하지 않습니다.");
	return;
}
%>