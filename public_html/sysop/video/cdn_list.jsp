<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.apache.commons.net.ftp.*" %>
<%@ page import="java.io.UnsupportedEncodingException" %>
<%@ include file="init.jsp" %><%

//기본키
if("".equals(siteinfo.s("cdn_ftp"))) {
	m.redirect("choice.jsp?" + m.qs());
	return;
}

//접근권한
//if(!Menu.accessible(69, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//변수
String mode = m.rs("mode");
String dir = m.rs("dir", "");
String parentDir = (!"".equals(dir) ? dir.substring(0, dir.lastIndexOf("/")) : "");

//객체
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();

//처리
if("add".equals(mode)) {
	//변수
	String[] idx = m.split(",", m.rs("idx"));
	int cid = m.ri("cid");
	int success = 0;
	
	//제한
	if(0 == cid) { m.jsAlert("콘텐츠는 반드시 지정해야 합니다."); return; }
	if(null == idx) { m.jsAlert("동영상은 반드시 선택해야 합니다."); return; }

	//등록
	for(int i = 0; i < idx.length; i++) {
		String[] temp = m.split("|", idx[i]);
		if(temp.length != 3) continue;

		String startUrl = siteinfo.s("cdn_url") + temp[2];
		if(0 < lesson.findCount("content_id = " + cid + " AND start_url = '" + startUrl + "' AND site_id = " + siteId + " AND status != -1")) continue;
		
		boolean infoBlock = false;
		if(startUrl.endsWith(".mp4")) {
			try{
				Process proc = Runtime.getRuntime().exec("sh /root/script/videoinfo.sh " + startUrl);
				BufferedReader br = new BufferedReader(new InputStreamReader(proc.getInputStream()));
				String line = br.readLine();
				br.close();

				String[] arr = line.split("\t");
				DataSet tlist = Json.decode(arr[0]);
				if(tlist.next()) {
					infoBlock = true;
					lesson.item("total_time", tlist.i("Duration") / 60 / 1000);
					lesson.item("complete_time", tlist.i("Duration") / 60 / 1000);
					lesson.item("content_width", tlist.i("Width"));
					lesson.item("content_height", tlist.i("Height"));
				}
			}
			catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
			catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
		}

		if(!infoBlock) {
			lesson.item("complete_time", 0);
			lesson.item("content_width", 1280);
			lesson.item("content_height", 720);
		}

		lesson.item("site_id", siteId);
		lesson.item("content_id", cid);
		lesson.item("lesson_nm", temp[1]);
		lesson.item("onoff_type", "N"); //온라인
		lesson.item("lesson_type", "03");
		lesson.item("author", "");
		lesson.item("start_url", startUrl);
		lesson.item("mobile_a", startUrl);
		lesson.item("mobile_i", startUrl);
		lesson.item("total_page", 0);
		lesson.item("description", "");
		lesson.item("manager_id", userId);
		lesson.item("use_yn", "Y");
		lesson.item("sort", lesson.getMaxSort(cid, "Y", siteId));
		lesson.item("reg_date", m.time("yyyyMMddHHmmss"));
		lesson.item("status", 1);
		if(lesson.insert()) success++;
	}
	
	//이동
	m.js(
		"if(confirm('총 " + idx.length + "건 중 " + success + "건을 등록했습니다.\\n\\n강의 순서와 인정시간은 별도로 지정하셔야 합니다.\\n강의목차로 이동하시겠습니까?')) {"
			+ "parent.location.href = '../content/lesson_list.jsp?cid=" + cid + "';"
		+ "} else {"
			+ "parent.location.reload();"
		+ "}"
	);
	return;
}

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

	int loginResult = loginValidate(ftp, m, arr[1], arr[2]);
	if(-1 == loginResult) {
		ftp.disconnect();
		m.jsError("FTP 접속시도가 너무 많습니다. 잠시 후 다시 시도하세요.");
		return;
	} else if (-2 == loginResult) {
		ftp.disconnect();
		m.jsError("FTP 접속정보가 일치하지 않습니다. 관리자에게 문의하세요.");
		return;
	}

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
	if(ftp.isConnected()) {
		ftp.logout();
		ftp.disconnect();
	}

} catch(UnsupportedEncodingException uee) {
	m.log("ftp", uee.toString());
	m.jsAlert("CDN에 접속하는 중 오류가 발생했습니다.");
	return;
} catch(Exception e) {
	m.log("ftp", e.toString());
	m.jsAlert("CDN에 접속하는 중 오류가 발생했습니다.");
	return;
}

//출력
p.setLayout(ch);
p.setBody("video.cdn_list");
p.setVar("p_title", "콘텐츠 파일 관리");
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

%>