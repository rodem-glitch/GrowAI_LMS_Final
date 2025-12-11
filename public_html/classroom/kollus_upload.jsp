<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//기본값
String module = m.rs("md", "post");
int moduleId = m.ri("mid");
String mode = m.rs("mode");

//객체
KollusDao kollus = new KollusDao(siteId);
KollusFileDao kollusFile = new KollusFileDao();

if("json".equals(mode)) {
    String json = kollus.getUploadUrl(SiteConfig.s("kollus_clpost_key"), 0);
    if("https".equals(request.getScheme())) json = m.replace(json, "http:\\/\\/", "https:\\/\\/");
    out.print(json);
    return;
} else if("set".equals(mode)) {
    String uploadFileKey = m.rs("key");
    kollusFile.item("upload_file_key", uploadFileKey);
    if(!kollusFile.insert()) {
        out.print("콜러스 영상을 업로드 하는 중 오류가 발생 했습니다.");
        return;
    }
    out.print("업로드에 성공하였습니다.");
    return;
}

//출력
p.setLayout("blank");
p.setBody("classroom.kollus_upload");

p.setVar("category_key", SiteConfig.s("kollus_clpost_key"));

p.display();

%>