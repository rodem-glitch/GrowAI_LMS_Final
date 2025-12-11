<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(30, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LessonDao lesson = new LessonDao();

String ckManager = m.getCookie("ck_manager_id");

//폼체크
f.addElement("lesson_nm", null, "hname:'콘텐츠객체명', required:'Y'");
f.addElement("total_time", m.parseInt(m.getCookie("ck_total_time")), "hname:'학습시간', option:'number'");
f.addElement("manager_nm", ("".equals(ckManager) ? "" : lesson.getOne("SELECT name FROM TB_USER WHERE id = '" + ckManager + "'")), "hname:'담당자아이디'");
f.addElement("lesson_type", "".equals(m.getCookie("ck_lesson_type")) ? "01" : m.getCookie("ck_lesson_type"), "hname:'동영상타입', required:'Y'");
f.addElement("start_url", null, "hname:'시작파일'");
f.addElement("mobile_a", null, "hname:'시작파일'");
f.addElement("mobile_i", null, "hname:'시작파일'");
f.addElement("total_page", m.parseInt(m.getCookie("ck_total_page")), "hname:'총페이지', option:'number'");
f.addElement("complete_time", m.parseInt(m.getCookie("ck_complete_time")), "hname:'인정시간', option:'number'");
f.addElement("author", m.getCookie("ck_author"), "hname:'저작자'");
f.addElement("content_height", m.parseInt(m.getCookie("ck_content_height")), "hname:'창높이', option:'number'");
f.addElement("content_width", m.parseInt(m.getCookie("ck_content_width")), "hname:'창넓이', option:'number'");
f.addElement("status", 1, "hname:'상태', required:'Y'");
f.addElement("description", null, "hname:'객체설명'");

if(m.isPost() && f.validate()) {

	int newId = lesson.getSequence();

	lesson.item("id", newId);
	lesson.item("site_id", siteinfo.i("id"));
	lesson.item("lesson_nm", f.get("lesson_nm"));
	lesson.item("lesson_type", f.get("lesson_type"));
	lesson.item("start_url", f.get("start_url"));
	lesson.item("mobile_a", f.get("mobile_a"));
	lesson.item("mobile_i", f.get("mobile_i"));
	lesson.item("total_page", f.getInt("total_page"));
	lesson.item("total_time", f.getInt("total_time"));
	lesson.item("complete_time", f.getInt("complete_time"));
	lesson.item("content_width", f.getInt("content_width"));
	lesson.item("content_height", f.getInt("content_height"));
	lesson.item("manager_id", f.getInt("manager_id"));
	lesson.item("author", f.get("author"));
	lesson.item("reg_date", m.time("yyyyMMddHHmmss"));
	lesson.item("status", f.getInt("status"));
	lesson.item("description", f.get("description"));

	if(null != f.getFileName("lesson_file")) {
		File file1 = f.saveFile("lesson_file");
		if(null != file1) lesson.item("lesson_file", f.getFileName("lesson_file"));
	}

	if(!lesson.insert()) {
		m.jsAlert("등록하는 중 오류가 발생했습니다.");
		return;
	}

	m.setCookie("ck_total_time", f.get("total_time"), 86400);
	m.setCookie("ck_manager_id", f.get("manager_id"), 86400);
	m.setCookie("ck_total_time", f.get("total_time"), 86400);
	m.setCookie("ck_lesson_type", f.get("lesson_type"), 86400);
	m.setCookie("ck_author", f.get("author"), 86400);
	m.setCookie("ck_content_width", f.get("content_width"), 86400);
	m.setCookie("ck_content_height", f.get("content_height"), 86400);
	m.setCookie("ck_complete_time", f.get("complete_time"), 86400);
	m.setCookie("ck_total_page", f.get("total_page"), 86400);

	m.jsReplace("lesson_list.jsp", "parent");
	return;
}

//출력
p.setBody("lesson.lesson_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("lesson_types", m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes));
p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.setVar("manager_id", ckManager);
p.display();

%>
