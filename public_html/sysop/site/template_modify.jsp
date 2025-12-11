<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.apache.commons.net.ftp.*" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(12, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

String path = m.rs("path", "");
String templatePath = "/Users/kyounghokim/IdeaProjects/MalgnLMS/public_html/html/" + path;
String userPath = siteinfo.s("doc_root") + "/html/" + path;

File f1 = new File(userPath);
boolean isUserExists = f1.exists();

if(!isUserExists) {
	f1 = new File(templatePath);
	if(!f1.exists()) {
		m.jsAlert("해당 파일이 없습니다.");
		return;
	}
}

if(!f1.isFile() || !f1.canRead() || f1.isDirectory() == true) {
	m.jsAlert("올바른 파일이 아닙니다.");
	return;
}

StringBuffer sb = new StringBuffer();
//읽기
try {
	BufferedReader br = new BufferedReader(new FileReader(f1));
	String str = br.readLine();

	while(str != null) {
	  sb.append(str);
	  str = br.readLine();
	}
	
	br.close();
} catch(IOException ioe) {
	m.errorLog("IOException : " + ioe.getMessage(), ioe);
}

out.print(sb.toString());

/*

//출력
p.setLayout(ch);
p.setBody("site.template_view");
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
				result += path + "/" + flist[i] + "\t|\t" + f2.length() + "<br>\n";
			}
		}
		return result;
	} catch (NullPointerException npe) {
		Malgn.errorLog("NullPointerException : " + npe.getMessage(), npe);
		return "";
	}

}%>