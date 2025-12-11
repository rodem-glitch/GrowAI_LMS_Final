<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(69, userId, userKind) && !Menu.accessible(105, userId, userKind) && !Menu.accessible(106, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
String mode = m.rs("mode");

//객체
KollusDao kollus = new KollusDao(siteId);
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();


if("json".equals(mode)) {
	String json = kollus.getUploadUrl(f.get("category_key"), f.getInt("use_encryption"));
	if("https".equals(request.getScheme())) json = m.replace(json, "http:\\/\\/", "https:\\/\\/");
	out.print(json);
	return;
}

//카테고리
String categoryKey = null;
DataSet rs = kollus.getCategories();
DataSet categories = new DataSet();
while(rs.next()) if(!"None".equals(rs.s("name"))) categories.addRow(rs.getRow());

if("user".equals(siteinfo.s("kollus_channel")) && !superBlock) {
	categoryKey = kollus.getCategoryKey(categories, loginId);
} else {
	categoryKey = kollus.getCategoryKey(categories, null);
}

if("".equals(categoryKey)) {
	m.jsError("유효한 카테고리가 존재하지 않습니다. 관리자에게 문의바랍니다.");
	return;
}

//폼체크
f.addElement("category_key", categoryKey, "user".equals(siteinfo.s("kollus_channel")) && !superBlock ? "disabled:'disabled'" : null);

//출력
p.setBody("video.kollus_upload");
p.setVar("form_script", f.getScript());
p.setLoop("categories", categories);
p.setVar("encrypt_block", !"user".equals(siteinfo.s("kollus_channel")));
p.display();

%>