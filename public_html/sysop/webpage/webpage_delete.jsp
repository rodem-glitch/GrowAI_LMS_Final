<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(127, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
WebpageDao webpage = new WebpageDao();
FileDao file = new FileDao();
SiteDao site = new SiteDao();

//파일
String pageDir = tplRoot + "/page";
File pdir = new File(pageDir);
if(!pdir.exists()) pdir.mkdirs();

//정보
DataSet info = webpage.find("id = " + id + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
webpage.item("status", -1);
if(!webpage.update("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//삭제-파일
DataSet files = file.getFileList(info.i("attach_file"));
while(files.next()) {
	if(!"".equals(files.s("filename"))) m.delFile(m.getUploadPath(files.s("filename")));
}

//삭제-파일
File pageFile = new File(pageDir + "/" + info.s("code") + ".html");
if(pageFile.exists()) m.delFileRoot(pageDir + "/" + info.s("code") + ".html");

//이동
m.jsReplace("webpage_list.jsp?" + m.qs("id,mode"));

%>