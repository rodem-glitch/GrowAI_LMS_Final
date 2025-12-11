<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String dir = m.rs("dir");
String file = m.rs("file");
if(file != null) {
    file = file.replaceAll("<", "&lt;").replaceAll(">", "&gt;");

    file = file.replaceAll("[\\*\\?\\[\\{\\(\\)\\^\\$'@%;:\\-#,]", "");
}

String allowExt = "jpg,jpeg,gif,png,pdf,hwp,txt,doc,docx,xls,xlsx,ppt,pptx,zip,alz,7z,rar,egg,mp3,html"; //컴마로 연결
int extIndex = file.lastIndexOf(".") + 1;

if(!m.inArray(file.substring(extIndex, file.length()), allowExt)) {
    m.jsAlert("다운로드가 허용되지 않은 파일입니다.");
    return;
}

if(dir.startsWith("/public_html")) dir = dir.replace("/public_html", "");

String path = siteinfo.s("doc_root") + dir + "/" + file;
File f1 = new File(path);
if(f1.exists()) m.download(path, file, 500);
else if(new File(m.replace(path, "/public_html", "")).exists()) m.download(m.replace(path, "/public_html", ""), file, 500);
else m.jsAlert(_message.get("alert.common.nofile"));

%>