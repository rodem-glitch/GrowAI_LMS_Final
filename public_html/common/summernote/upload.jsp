<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %><%@ include file="/init.jsp" %><%

//로그인
//if(0 == userId) { auth.loginForm(); return; }

//폼입력
String mid = m.rs("mid", "0");
String md = m.rs("md", "editor");

//객체
FileDao file = new FileDao();

//변수
String allowExt = "jpg|jpeg|gif|png";
int maxPostSize = 10; //Config.getInt("maxPostSize");

//폼체크
f.addElement("filename", "", "hname:'파일', required:'Y', allow:'" + allowExt + "'");

//제한-POST
if(!m.isPost()) { out.print("{\"success\":false, \"error\":\"올바르지 않은 접근입니다.\", \"reset\":true}"); return; }

//제한-파일유형
if(!f.validate()) { out.print("{\"success\":false, \"error\":\"" + f.errMsg + "\", \"reset\":true}"); return; }

//제한-파일크기
if((maxPostSize * 1024 * 1024) < f.getLong("filesize")) { out.print("{\"success\":false, \"error\":\"" + maxPostSize + "MB를 초과하여 업로드 할 수 없습니다.\", \"reset\":true}"); return; }

//등록
File attFile = f.saveFile("filename");
if(attFile == null) { out.print("{\"success\":false, \"error\":\"파일이 정상적으로 업로드되지 않았습니다.\", \"reset\":true}"); return; }

file.item("module", md);
file.item("module_id", mid);
file.item("site_id", siteId);
file.item("file_nm", f.getFileName("filename"));
file.item("filename", f.getFileName("filename"));
file.item("filetype", f.getFileType("filename"));
file.item("filesize", attFile.length());
file.item("realname", attFile.getName());
file.item("main_yn", "N");
file.item("reg_date", m.time("yyyyMMddHHmmss"));
file.item("status", 1);
file.insert();

//파일리사이징
if(f.getFileName("filename").matches("(?i)^.+\\.(jpg|jpeg|png|gif|bmp)$")) {
    if(300 * 1024 < attFile.length()) { //300KB
        String imgPath = m.getUploadPath(f.getFileName("filename"));
        String cmd = "convert -resize 1200x> " + imgPath + " " + imgPath;
        Malgn.exec(cmd).trim();
    }
}

//출력
out.print("{\"success\":true, \"file\":\"" + ("mail".equals(m.rs("mode")) ? "http://" + siteinfo.s("domain") : "") + "/data/file/" + attFile.getName() + "\"}");
return;

%>