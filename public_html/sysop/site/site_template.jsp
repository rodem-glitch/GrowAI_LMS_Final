<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//기본키
String key = m.rs("k");
String ek = m.rs("ek");
String dir = m.rs("dir", !"".equals(m.getCookie("_LMS2016_TEMPLATE_DIR")) ? m.getCookie("_LMS2016_TEMPLATE_DIR") : "mail");
if("".equals(key) || "".equals(ek) || "".equals(dir)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//접근권한
if(!m.encrypt("SITE_HTML_" + key + "_WJ93F" + m.time("yyyyMMdd")).equals(ek)) {
	m.jsError("올바른 접근이 아닙니다."); return;
}

//정보
DataSet _bsinfo = Site.find("id = 1");
if(!_bsinfo.next()) { m.jsAlert("기본 사이트 정보가 없습니다."); return; }

//변수
String sourcePath = _bsinfo.s("doc_root") + "/html/" + dir + "/";
String targetPath = siteinfo.s("doc_root") + "/html/" + dir + "/";

m.setCookie("_LMS2016_TEMPLATE_DIR", dir);

out.println("<form>");
out.println("<input type=\"hidden\" name=\"k\" value=\"" + key + "\">");
out.println("<input type=\"hidden\" name=\"ek\" value=\"" + ek + "\">");
out.println(_bsinfo.s("doc_root") + "/html/<input type=\"text\" name=\"dir\" value=\"" + dir + "\" required=\"required\">/");
out.println("<input type=\"submit\" value=\"조회\">");
out.println("</form>");

out.println("<pre style=\"white-space:pre-wrap;\">");
out.println("소스경로 : " + sourcePath);
out.println("대상경로 : " + targetPath);
out.println("");

out.println("===[점검결과]===");

//목록-소스
DataSet slist = getFileList(sourcePath);
String[] sfiles = new String[slist.size()];
slist.sort("id", "asc");
slist.first();

//점검-소스
while(slist.next()) {
	sfiles[slist.getIndex()] = slist.s("id");

	File sfile = new File(sourcePath + slist.s("name"));
	File tfile = new File(targetPath + slist.s("name"));

	if(tfile.isFile() && 0 > tfile.getCanonicalPath().indexOf(sourcePath)) {

		out.print("복사됨 ■ ");

		BufferedReader sreader = new BufferedReader(new FileReader(sourcePath + slist.s("name")));
		BufferedReader treader = new BufferedReader(new FileReader(targetPath + slist.s("name")));

		try {   
			String sline = "";
			String tline = "";
			ArrayList<String> stemp = new ArrayList<String>();
			ArrayList<String> ttemp = new ArrayList<String>();
			while((sline = sreader.readLine()) != null) { stemp.add(sline); }
			while((tline = treader.readLine()) != null) { ttemp.add(tline); }

			/*
			for(int i = 0; i < stemp.size(); i++) {
				boolean temp = false;
				for(int j = 0; j < ttemp.size(); j++) {
					if(stemp.get(i).equals(ttemp.get(j))) { temp = true; }
				}
				if(!temp) { out.print("★"); } //out.println(stemp.get(i));
			}
			*/

			boolean temp = stemp.size() == ttemp.size();
			if(temp) {
				for(int i = 0; i < stemp.size(); i++) {
					try {
						if(!stemp.get(i).equals(ttemp.get(i))) { temp = false; }
					} catch(IndexOutOfBoundsException e) {
						temp = false;
					}
				}
			}

			if(!temp) {
				out.print("수정됨 ■ ");
			} else {
				out.print("동일함 □ ");
			}

		} finally {
			sreader.close();
			treader.close();
		}
	} else if(-1 < tfile.getCanonicalPath().indexOf(sourcePath)) {
		out.print("심볼릭──");
		out.print("─────");
	} else {
		out.print("미존재──");
		out.print("─────");
	}
	out.println(slist.s("name"));
	//out.println(targetPath + slist.s("name"));
}

//변수
String sourceFiles = "|" + m.join("|", sfiles) + "|";

out.println("");
out.println("===[기타파일]===");

//목록-대상
DataSet tlist = getFileList(targetPath);
tlist.sort("id", "asc");
tlist.first();
while(tlist.next()) {
	if(0 > sourceFiles.indexOf("|" + tlist.s("id") + "|")) { out.println(tlist.s("name")); }
}
out.println("");
out.println("");

out.println("</pre>");

%><%!
public DataSet getFileList(String path) throws Exception {
	DataSet ds = new DataSet();
	File dir = new File(path);
	if(!dir.exists()) return ds;

	try {
		File[] files = dir.listFiles();
		if(null == files) throw new NullPointerException();
		for (int i = 0; i < files.length; i++) {
			if(null == files[i]) throw new NullPointerException();
			String filename = files[i].getName();
			ds.addRow();
			ds.put("id", filename.substring(0, filename.length() - 5));
			ds.put("name", filename);
		}
		return ds;
	} catch (NullPointerException npe) {
		Malgn.errorLog("NullPointerException : " + npe.getMessage(), npe);
		return new DataSet();
	}

}
%>