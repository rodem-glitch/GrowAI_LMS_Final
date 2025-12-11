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

//파일
String tplDir = "/home/" + siteinfo.s("ftp_id") + "/public_html";
String pdir = tplDir + "/html/" + dir;
File pd = new File(pdir);
if(!pd.exists()) { m.jsAlert("해당 경로에 폴더가 없습니다. \\n경로 - " + pdir); return; }

String pfile = pdir + "/" + pnm + "." + ext;
File pf = new File(pfile);
if(!pf.exists()) { m.jsAlert("해당 경로에 파일이 없습니다. \\n파일 - " + pfile); return; }

//백업폴더
String bdir = tplDir + "/html/" + dir + "/_backup";
File bd = new File(bdir);
if(!bd.exists()) bd.mkdirs();


//목록
DataSet flist = new DataSet();
File[] files = bd.listFiles();
for(int i = 0; i < files.length; i++) {
	String filename = files[i].getName();
	if(filename.indexOf(pnm) == 0) {  //오류
		String fdate = m.replace(filename, new String[] {pnm + "_", "." + ext}, "");
		flist.addRow();
		flist.put("id", filename);
		flist.put("name", m.time("yyyy.MM.dd HH:mm:ss", fdate));
	}
}
if(flist.size() > 0) {
	flist.sort("id", "desc");
	flist.move(0);
} else {
	m.jsErrClose("백업된 파일이 없습니다.");
	return;
}

//폼체크
String sfn = !"".equals(m.rs("s_file")) ? m.rs("s_file") : flist.s("id");
f.addElement("s_file", sfn, null);

String bfile = "";
String content = "";
if(!"".equals(sfn)) {
	bfile = bdir + "/" + sfn;
	File bf = new File(bfile);
	if(!bf.exists()) { m.jsAlert("해당 경로에 백업 파일이 없습니다. \\n파일 - " + bfile); return; }
	content = m.readFile(bfile);
}

//출력
p.setLayout("pop");
p.setBody("design.layout_backup");
p.setVar("p_title", "백업 파일 확인");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("ppath", m.replace(bfile, tplDir, ""));
p.setVar("content", content);

p.setLoop("files", flist);
p.setVar("file_cnt", flist.size());

p.display();

%>