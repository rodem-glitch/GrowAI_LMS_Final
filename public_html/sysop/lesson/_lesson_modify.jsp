<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(30, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LessonDao lesson = new LessonDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = lesson.query(
	" SELECT a.*, b.user_nm "
	+ " FROM " + lesson.table + " a "
	+ " LEFT JOIN TB_USER b ON a.manager_id = b.id "
	+ " WHERE a.id = " + id
);
if(!info.next()) { m.jsError("해당 정보를 찾을 수 없습니다."); return; }

//파일삭제
if("fdel".equals(m.request("mode"))) {
	if(!"".equals(info.s("lesson_file"))) {
		lesson.item("lesson_file", "");
		if(!lesson.update("id = " + info.i("id"))) {}
	}
	return;
}

//폼체크
f.addElement("lesson_nm", info.s("lesson_nm"), "hname:'콘텐츠명', required:'Y'");
f.addElement("total_time", info.i("total_time"), "hname:'학습시간', option:'number'");
f.addElement("manager_nm", info.s("user_nm"), "hname:'담당자아이디'");
f.addElement("decription", null, "hname:'설명'");
f.addElement("lesson_type", info.s("lesson_type"), "hname:'동영상타입', required:'Y'");
f.addElement("start_url", info.s("start_url"), "hname:'시작파일'");
f.addElement("mobile_a", info.s("mobile_a"), "hname:'시작파일'");
f.addElement("mobile_i", info.s("mobile_i"), "hname:'시작파일'");
f.addElement("total_page", info.i("total_page"), "hname:'총페이지', option:'number'");
f.addElement("complete_time", info.i("complete_time"), "hname:'인정시간', option:'number'");
f.addElement("author", info.s("author"), "hname:'저작자'");
f.addElement("content_height", info.i("content_height"), "hname:'창높이', option:'number'");
f.addElement("content_width", info.i("content_width"), "hname:'창넓이', option:'number'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");
f.addElement("lesson_file", null, "hname:'교안파일'");

if(m.isPost() && f.validate()) {

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
	lesson.item("status", f.getInt("status"));
	lesson.item("description", f.get("description"));

	if(null != f.getFileName("lesson_file")) {
		File file1 = f.saveFile("lesson_file", f.uploadDir + "/" + info.i("id") + "_lesson_file");
		if(null != file1) lesson.item("lesson_file", f.getFileName("lesson_file"));
	}

	if(!lesson.update("id = " + id)) {
		m.jsAlert("수정하는 중 오류가 발생했습니다.");
		return;
	}
	m.jsReplace("lesson_list.jsp?" + m.qs("id"), "parent");
	return;
}

info.put("lesson_file_conv", m.encode(info.s("lesson_file")));
info.put("lesson_file_ek", m.encrypt(info.s("lesson_file") + m.time("yyyyMMdd")));
info.put("lesson_file_path", m.encode(f.uploadDir + "/" + info.i("id") + "_lesson_file"));

//출력
p.setBody("lesson.lesson_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("lesson_types", m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes));
p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.setVar(info);
p.setVar("manage_id", info.i("manager_id"));
p.setVar("modify", true);
p.display();

%>
