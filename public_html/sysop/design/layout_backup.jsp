<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init_layout.jsp" %><%

//접근권한
if(!Menu.accessible(45, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String pnm = m.rs("pnm");
String dir = m.rs("dir");
if("".equals(pnm) || "".equals(mode) || "".equals(dir)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//페이지명
String ext = "html";
if("layout".equals(mode)) {
	p.setVar("emode", "htmlmixed");
} else if("css".equals(mode)) {
	ext = "css";
	p.setVar("emode", "css");
}

//목록
Json jb = new Json(apiUrl + "?mode=files&uid=" + siteinfo.s("ftp_id") + "&folder=" + dir + "/_backup&pnm=" + pnm);
DataSet files = jb.getDataSet("//files");
if(files.size() > 0) {
	files.sort("id", "desc");
	files.move(0);
} else {
	m.jsErrClose("백업된 파일이 없습니다.");
	return;
}

//폼체크
String sfn = !"".equals(m.rs("s_file")) ? m.rs("s_file") : files.s("name");
f.addElement("s_file", sfn, null);

String content = "";
if(!"".equals(sfn)) {
	Http httpRead = new Http(apiUrl);
	httpRead.setParam("mode", "read");
	httpRead.setParam("uid", siteinfo.s("ftp_id"));
	httpRead.setParam("folder", dir + "/_backup");
	httpRead.setParam("file", sfn);
	content = httpRead.send("GET");
}

//출력
p.setLayout("pop");
p.setBody("design.layout_backup");
p.setVar("p_title", "백업 파일 확인");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

//p.setVar("ppath", m.replace(bfile, tplDir, ""));
p.setVar("content", content);

p.setLoop("files", files);
p.setVar("file_cnt", files.size());

p.display();

%>