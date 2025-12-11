<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.apache.commons.net.ftp.*" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(12, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

String RootPath = "/Users/kyounghokim/IdeaProjects/MalgnLMS/public_html/html";
String list = explorer(RootPath);
list = list.replace(RootPath + "/", "");
out.print(list);

/*
//변수
String mode = m.rs("mode");
String dir = m.rs("dir", "");
String parentDir = (!"".equals(dir) ? dir.substring(0, dir.lastIndexOf("/")) : "");

//객체
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//변수
String[] arr = m.split("|", siteinfo.s("cdn_ftp"));
String[] ord = m.split(" ", !"".equals(m.rs("ord")) ? m.rs("ord") : "type DESC");

if("C".equals(userKind) && !dir.startsWith("/" + userId)) dir = "/" + userId;

//목록
DataSet list = new DataSet();
FTPClient ftp = new FTPClient();
try {
	ftp.setControlEncoding("utf-8");
	ftp.connect(arr[0]);
	ftp.enterLocalPassiveMode();
	ftp.login(arr[1], arr[2]);
	if(!ftp.changeWorkingDirectory(dir)) {
		ftp.makeDirectory(dir);
	}
	FTPFile[] files = ftp.listFiles(dir);

	for(int i=0; i<files.length; i++) {
		String fileName = files[i].getName();
		if(fileName.startsWith(".")) continue;

		if(!"".equals(f.get("s_keyword"))) {
			if("name".equals(f.get("s_field"))) {
				if(!files[i].isDirectory() && 0 > fileName.toLowerCase().indexOf(f.get("s_keyword").toLowerCase())) continue;
			}
		}

		list.addRow();
		list.put("idx", i+1);
		list.put("path", dir + "/" + fileName);
		list.put("name", fileName);
		list.put("ext", m.getFileExt(fileName));
		list.put("title", list.s("name").replace("." + list.s("ext"), ""));
		list.put("size", m.getFileSize(files[i].getSize()));
		list.put("reg_date", m.time("yyyy-MM-dd HH:mm", files[i].getTimestamp().getTime()));
		list.put("is_folder", files[i].isDirectory());
		list.put("is_mp4", "mp4".equals(list.s("ext")));
		list.put("is_link", !files[i].isDirectory() && !"mp4".equals(list.s("ext")));
		list.put("type", files[i].isDirectory() ? "폴더" : "파일");
	}
	list.sort(ord[0], ord[1]);

	ftp.logout();
	ftp.disconnect();
} catch(Exception e) {
	m.jsAlert("CDN에 접속하는 중 오류가 발생했습니다.");
	return;
}

//출력
p.setLayout(ch);
p.setBody("site.template_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("dir,s_field,s_keyword"));
p.setVar("form_script", f.getScript());
if("select".equals(m.rs("mode"))) p.setVar("SYS_TABLE_WIDTH", 900);

p.setLoop("list", list);
p.setVar("list_total", list.size());

p.setLoop("content_list", content.find("status != -1 AND site_id IN (0, " + siteId + ") ORDER BY id DESC", "id, content_nm"));

p.setVar("dir", dir);
p.setVar("parent_dir", parentDir);
p.setVar("select_mode", "select".equals(m.rs("mode")));
p.setVar("cdn_url", siteinfo.s("cdn_url"));
p.display();
*/

%><%!
public static String explorer(String path) {
	String result = "";
	path = path.replace("\\", "/");
	try {
		File f1 = new File(path);
		String[] flist = f1.list();
		if(null == flist) throw new NullPointerException();
		for (int i = 0; i < flist.length; i++) {
			if(null == flist[i]) throw new NullPointerException();
			File f2 = new File(f1 + "/" + flist[i]);
			if (f2.isDirectory() == true) {
				result += explorer(f1 + "/" + flist[i]);
			} else {
				result += "<a href=\"template_modify.jsp?path=" + path + "/" + flist[i] + "\">" + path + "/" + flist[i] + "\t|\t" + f2.length() + "</a><br>\n";
			}
		}
		return result;
	} catch (NullPointerException npe) {
		Malgn.errorLog("NullPointerException : " + npe.getMessage(), npe);
		return "";
	}

}%>