<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//로그인
if(0 == userId) { auth.loginForm(); return; }

//폼입력
String md = m.rs("md", "post");
String mid = m.rs("mid");
int w = m.ri("w");
int h = m.ri("h");

//객체
FileDao file = new FileDao();

//폼체크
f.addElement("filename", "", "hname:'파일', required:'Y', allow:'swf|mp4|flv|mov|qt|mpeg|wmv|wma|asf|mp3|avi|wmp|rmp|ra'");
f.addElement("width", w, "hname:'가로크기', required:'Y', option:'number'");
f.addElement("height", h, "hname:'세로크기', required:'Y', option:'number'");

//등록
if(m.isPost() && f.validate()) {

	File attFile = f.saveFile("filename");

	if(null != attFile) {

		file.item("module", md);
		file.item("module_id", mid);
		file.item("site_id", siteId);
		file.item("filename", f.getFileName("filename"));
		file.item("filetype", f.getFileType("filename"));
		file.item("realname", attFile.getName());
		file.item("filesize", attFile.length());
		file.item("main_yn", "N");
		file.item("reg_date", m.time("yyyyMMddHHmmss"));
		file.item("status", 1);

		file.insert();

		out.print("<script>opener.iContent("
			+ "'" + m.getUploadUrl(f.getFileName("filename")) + "'"
			+ ", '" + (!"".equals(m.rs("tgt")) ? m.rs("tgt") : "content") + "'"
			+ ", '" + f.get("width") + "'"
			+ ", '" + f.get("height") + "'"
			+ ");</script>");
	}
	out.print("<script>opener.fileupload.location.href = opener.fileupload.location.href;</script>");
	out.print("<script>window.close();</script>");
	return;
}

//페이지 출력
p.setLayout("blank");
p.setBody("board.file_movie");
p.setVar("p_title", "동영상 등록");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs(""));
p.setVar("list_query", m.qs("id"));
p.display();

%>