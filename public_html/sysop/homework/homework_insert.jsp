<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.30

//접근권한
if(!Menu.accessible(73, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
HomeworkDao homework = new HomeworkDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();

//폼체크
f.addElement("onoff_type", "N", "hname:'구분', required:'Y'");
f.addElement("category_id", null, "hname:'카테고리명'");
f.addElement("homework_nm", null, "hname:'과제명', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
f.addElement("homework_file", null, "hname:'첨부파일'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	String content = f.get("content");
	//제한-이미지URI
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}

	//제한-용량
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)");
		return;
	}

	int newId = homework.getSequence();
	homework.item("id", newId);
	homework.item("site_id", siteId);
	homework.item("onoff_type", f.get("onoff_type", "N"));
	homework.item("category_id", f.get("category_id"));
	homework.item("homework_nm", f.get("homework_nm"));
	homework.item("content", content);
	homework.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	homework.item("reg_date", m.time("yyyyMMddHHmmss"));
	homework.item("status", f.getInt("status"));

	if(null != f.getFileName("homework_file")) {
		File f1 = f.saveFile("homework_file");
		if(f1 != null) homework.item("homework_file", f.getFileName("homework_file"));
	}

	if(!homework.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("homework_list.jsp", "parent");
	return;

}


//출력
p.setBody("homework.homework_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(homework.statusList));
p.setLoop("onoff_types", m.arr2loop(homework.onoffTypes));
p.setLoop("categories", category.getList(siteId));
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>