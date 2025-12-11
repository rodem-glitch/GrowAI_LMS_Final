<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//폼입력
String md = m.rs("md", "post");
String mid = m.rs("mid");
int w = m.ri("iw");
int h = m.ri("ih");

//객체
FileDao file = new FileDao();
PostDao post = new PostDao();

//변수
int width = w == 0 ? (post.getContentWidth() - 20) : w;

//폼체크
f.addElement("filename", "", "hname:'파일', required:'Y', allow:'jpg|jpeg|gif|png'");
f.addElement("width", width, "hname:'가로크기', required:'Y'");
f.addElement("height", h == 0 ? "auto" : h + "", "hname:'세로크기', required:'Y'");

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

		//파일리사이징
		try {
			width = width >= 300 ? (width < 1000 ? width : 1000) : 300;
			String imgPath = m.getUploadPath(f.getFileName("filename"));
			String cmd = "convert -resize " + width + "x " + imgPath + " " + imgPath;
			Runtime.getRuntime().exec(cmd);
		}
		catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
		catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }

		out.print("<script>opener.iContent("
			+ "'" + siteDomain + m.getUploadUrl(f.getFileName("filename")) + "'"
			+ ", '" + (!"".equals(m.rs("tgt")) ? m.rs("tgt") : "content") + "'"
			+ ", '" + f.get("width") + "'"
			+ ", '" + f.get("height") + "'"
			+ ");</script>");
	}

	out.print("<script>opener.fileupload.location.href = opener.fileupload.location.href;</script>");
//	out.print("<script>try { ResizeIframe(opener.fileupload.parent.name); } catch(e) {}</script>");
	out.print("<script>window.close();</script>");
	return;
}

//출력
p.setLayout("blank");
p.setBody("board.file_image");
p.setVar("p_title", "이미지 등록");
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.display(out);

%>