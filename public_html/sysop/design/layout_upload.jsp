<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//객체
FileDao file = new FileDao();

//변수
String allowExt = "jpg|jpeg|gif|png"; //file.allowExt;
int maxPostSize = 3;
String md = "image";
int mid = 0;

//폼체크
f.addElement("filename", "", "hname:'파일', required:'Y', allow:'" + allowExt + "'");

//업로드
if(m.isPost()) {

	//제한-파일유형
	if(!f.validate()) { out.print("{\"success\":false, \"error\":\"" + f.errMsg + "\", \"reset\":true}"); return; }

	//제한-파일크기
	if((maxPostSize * 1024 * 1024) < f.getLong("filesize")) { out.print("{\"success\":false, \"error\":\"3MB를 초과하여 업로드 할 수 없습니다.\", \"reset\":true}"); return; }

	//등록
	File attFile = f.saveFile("filename");
	if(attFile == null) { out.print("{\"success\":false, \"error\":\"파일이 정상적으로 업로드되지 않았습니다.\", \"reset\":true}"); return; }

	//file.d(out);
	file.item("module", md);
	file.item("module_id", mid);
	file.item("site_id", siteId);
	file.item("file_nm", f.getFileName("filename"));
	file.item("filename", f.getFileName("filename"));
	file.item("filetype", f.getFileType("filename"));
	file.item("filesize", attFile.length());
	file.item("realname", attFile.getName());
	file.item("main_yn", "N");
	file.item("reg_date", m.time("yyyyMMddHHmmss"));
	file.item("status", 1);
	file.insert();

	//제한-오류
	//if(!"".equals(file.errMsg)) { out.print("{\"success\":false, \"error\":\"" + file.errMsg + "\", \"reset\":true}"); return; }

	//파일리사이징
	try {
		if (f.getFileName("filename").matches("(?i)^.+\\.(jpg|png|gif|bmp)$")) {
			String imgPath = m.getUploadPath(f.getFileName("filename"));
			String cmd = "convert -resize 1200x> " + imgPath + " " + imgPath;
			Runtime.getRuntime().exec(cmd);
		}
	} catch (RuntimeException re) {
		m.errorLog("RuntimeException : " + re.getMessage(), re);
	} catch (Exception e) {
		m.errorLog("Exception : " + e.getMessage(), e);
	}

	out.print("{\"success\":true}");
	return;
}


%>