<%@ page contentType="text/html; charset=utf-8" %><%@ page import="malgnsoft.json.*" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(69, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
String mode = m.rs("mode");

//객체
KollusDao kollus = new KollusDao(siteId);
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();


if("json".equals(mode)) {
	String json = kollus.getUploadUrl(f.get("category_key"), f.getInt("use_encryption"));
	out.print(json);
	return;
}

//카테고리
DataSet categories = kollus.getCategories();
String categoryKey = null;

if(!"".equals(siteinfo.s("kollus_channel"))) {
	while(categories.next()) {
		if(categories.s("name").equals(siteinfo.s("ftp_id"))) {
			categoryKey = categories.s("key");
			break;
		}
	}
}

//폼체크
f.addElement("category_key", categoryKey, categoryKey != null ? "disabled:'disabled'" : null);

//출력
p.setBody("kollus.kollus_upload");
p.setVar("form_script", f.getScript());
p.setLoop("categories", categories);
p.display();

%>