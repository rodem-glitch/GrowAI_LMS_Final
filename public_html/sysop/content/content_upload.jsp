<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
String dir = m.decode(m.rs("dir"));
if(cid == 0 || "".equals(dir)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ContentDao content = new ContentDao();

//정보
DataSet info = content.find("id = " + cid + " AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//변수
String contentDir = "/Users/kyounghokim/IdeaProjects/MalgnLMS/public_html/data/_Contents"; //임시
String[] replaceArr = { "\r\n", "\r", "\n" };

if(!"".equals(f.getFileName("filename"))) {
	//파일이 업로드된 경우
	File attach = f.saveFile("filename", dir + "/" + f.getFileName("filename"));
	if(null != attach) {
		if("zip".equals(m.rs("type")) && "zip".equals(m.getFileExt(f.getFileName("filename")).toLowerCase())) {

			File dfd = new File(dir);
			if(!dfd.exists()) { dfd.mkdirs(); };

			Zip zip = new Zip();
			zip.extract(attach, dir);
		}
	}
}

//출력
p.setLayout("blank");
p.setBody("content.content_upload");
p.setVar("p_title", "업로드");
p.setVar("query", m.qs());

p.setVar("web_url", siteDomain);
p.setVar("today", m.time("yyyyMMdd"));
p.display();

%>