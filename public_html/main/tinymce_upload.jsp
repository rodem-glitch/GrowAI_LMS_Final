<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
FileDao file = new FileDao();

//변수
String module = m.rs("mode");
int maxPostSize = 100;

//폼체크
f.addElement("file", null, "allow:'gif|jpg|jpeg|png'");

//업로드
if(m.isPost() && f.validate()) {
    
    //제한-파일유형
    if(!f.validate()) { out.print("{\"success\":false, \"error\":\"" + f.errMsg + "\", \"reset\":true}"); return; }
    
    //제한-파일크기
    if((maxPostSize * 1024 * 1024) < f.getLong("filesize")) { out.print("{\"success\":false, \"error\":\"100MB를 초과하여 업로드 할 수 없습니다.\", \"reset\":true}"); return; }
    
    File attFile = f.saveFile("file");
    if(attFile != null) {
        
        file.item("module", module);
        file.item("module_id", userId);
        file.item("site_id", siteId);
        file.item("file_nm", f.getFileName("file"));
        file.item("filename", f.getFileName("file"));
        file.item("filetype", f.getFileType("file"));
        file.item("filesize", attFile.length());
        file.item("realname", attFile.getName());
        file.item("main_yn", "N");
        file.item("reg_date", sysNow);
        file.item("status", 1);
        file.insert();
        
        //파일리사이징
        if (f.getFileName("file").matches("(?i)^.+\\.(jpg|jpeg|png|gif|bmp)$")) {
            String imgPath = m.getUploadPath(f.getFileName("file"));
            String cmd = "convert -resize 1200x> " + imgPath + " " + imgPath;
            Malgn.exec(cmd);
        }
        
        out.print("{\"location\":\"" + ("mail".equals(m.rs("mode")) ? "https://" + siteinfo.s("domain") : "") + "/data/file/" + attFile.getName() + "\"}");
    }
    
}

%>