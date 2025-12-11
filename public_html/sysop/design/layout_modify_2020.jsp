<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init_layout.jsp" %><%

//접근권한
if(!Menu.accessible(45, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String pnm = m.rs("pnm");
String dir = m.rs("dir");
if("".equals(pnm) || "".equals(dir)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//페이지명
String ptitle = null;
List<String> codes = null;
DataSet pages = null;
String ext = "html";
if("layout".equals(mode)) {
	ptitle = "레이아웃편집 - " + (layoutCodes.contains(pnm) ? m.getItem(pnm, layoutArr) : (pnm.startsWith("layout_") ? "기타 레이아웃 (" + m.replace(pnm, "layout_", "") + ")" : pnm)) + " [" + pnm + "]";
	codes = layoutCodes;
	pages = layouts;
	p.setVar("attach_block", true);
	p.setVar("emode", "htmlmixed");
} else if("css".equals(mode)) {
	ptitle = "CSS편집 - " + m.getItem(pnm, cssArr) + " [" + pnm + "]";
	codes = cssCodes;
	pages = m.arr2loop(cssArr);
	ext = "css";
	p.setVar("css_block", true);
	p.setVar("emode", "css");
}

//파일
/*
String tplDir = "/home/" + siteinfo.s("ftp_id") + "/public_html";
String pdir = tplDir + "/html/" + dir;
File pd = new File(pdir);
if(!pd.exists()) { m.jsAlert("해당 경로에 폴더가 없습니다. \\n경로 - " + pdir); return; }

String pfile = pdir + "/" + pnm + "." + ext;
File pf = new File(pfile);
if(!pf.exists()) {
	if(codes.contains(pnm)) {
		pf.createNewFile();
		m.exec("chown -R " + siteinfo.s("ftp_id") + ":" + siteinfo.s("ftp_id") + " " + pfile);
	} else {
		m.jsError("해당 경로에 파일이 없습니다. \\n파일 - " + pfile);
		return;
	}
}
String content = m.readFile(pfile);

//백업폴더
String bdir = tplDir + "/html/" + dir + "/_backup";
File bd = new File(bdir);
if(!bd.exists()) bd.mkdirs();
*/

//내용
Http httpRead = new Http(apiUrl);
httpRead.setParam("mode", "read");
httpRead.setParam("uid", siteinfo.s("ftp_id"));
httpRead.setParam("folder", dir);
httpRead.setParam("file", pnm + "." + ext);
String content = httpRead.send("GET");

//폼체크
f.addElement("content", null, "hname:'내용', allowscript:'Y', allowhtml:'Y', allowiframe:'Y', allowlink:'Y', allowobject:'Y'");

//저장
if(m.isPost() && f.validate()) {
	/*
	//백업
	if(!content.equals(f.get("content"))) {
		String bfile = bdir + "/" + pnm + "_" + m.time("yyyyMMddHHmmss") + "." + ext;
		m.writeFile(bfile, content);
	}
	m.writeFile(pfile, f.get("content"));
	*/

	Http httpWrite = new Http(apiUrl);
	httpWrite.setParam("mode", "edit");
	httpWrite.setParam("uid", siteinfo.s("ftp_id"));
	httpWrite.setParam("folder", dir);
	httpWrite.setParam("file", pnm + "." + ext);
	httpWrite.setParam("body", f.get("content"));
	out.print(httpWrite.send("POST"));

	//이동
	m.jsAlert("수정 되었습니다.");
	//m.jsReplace("layout_modify.jsp?mode=" + mode + "&dir=" + dir + "&pnm=" + pnm, "parent");
	return;
}

//출력
p.setBody("design.layout_insert");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

//p.setVar("ppath", m.replace(pfile, tplDir, ""));
p.setVar("content", content);
p.setVar("domain", siteinfo.s("domain"));

p.setLoop("pages", pages);
p.display();

%>