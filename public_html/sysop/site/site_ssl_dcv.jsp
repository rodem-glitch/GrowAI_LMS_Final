<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.*,java.io.*,dao.*,malgnsoft.db.*,malgnsoft.util.*,java.net.InetAddress,org.json.*" %><%

//객체
Malgn m = new Malgn(request, response, out);

Form f = new Form("form1");
try { f.setRequest(request); }
catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage()); return; }
catch(Exception ex) { m.errorLog("Overflow file size. - " + ex.getMessage()); return; }

//기본키
int sid = m.ri("sid");
String key = m.rs("k");
String ek = m.rs("ek");
if(1 > sid) { m.jsAlert("올바른 접근이 아닙니다. [1]"); return; }
if(!ek.equals(m.encrypt("DCV_SETTING_" + key + "_PCC_" + m.time("yyyyMMdd")))) { m.jsAlert("올바른 접근이 아닙니다. [2]"); return; }

//객체
SiteDao site = new SiteDao();

//정보
DataSet info = site.find("id = " + sid);
if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("dcv_nm", null, "hname:'DCV 파일명', required:'Y'");
f.addElement("dcv_contents", null, "hname:'DCV 파일내용', required:'Y'");

//수정
if(m.isPost() && f.validate()) {
	String fileDir = info.s("doc_root") + "/.well-known/pki-validation/";
	String fileName = f.get("dcv_nm");
	String filePath = fileDir + fileName;

	//디렉토리 생성
	try {
		new File(info.s("doc_root") + "/.well-known/pki-validation/").mkdirs();
	}
	catch (SecurityException se) { m.jsAlert("디렉토리 생성 오류"); }

	File sFile = new File(filePath);
	sFile.createNewFile();

	//파일쓰기
	FileWriter fw = new FileWriter(filePath);
	fw.write(f.get("dcv_contents"));
	fw.close();

	m.jsAlert("DCV 인증파일 생성 완료\\n" + filePath);
	return;
} else {
	m.jsAlert("올바른 접근이 아닙니다. [3]");
}

%>