<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
LessonDao lesson = new LessonDao();
UserDao user = new UserDao();

//정보
DataSet info = lesson.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	if(!"".equals(info.s("lesson_file"))) {
		lesson.item("lesson_file", "");
		if(!lesson.update("id = " + info.i("id"))) {
			m.jsErrClose("파일을 삭제하는 중 오류가 발생했습니다.");
			return;
		}
		m.delFileRoot(m.getUploadPath(info.s("lesson_file")));
	}
	return;
}

//이동-오프라인강의
if("N".equals(info.s("onoff_type"))) {
	m.jsReplace("../content/lesson_modify.jsp?id=" + id);
	return;
}

//폼체크
f.addElement("lesson_type", info.s("lesson_type"), "hname:'구분', required:'Y'");
f.addElement("lesson_nm", info.s("lesson_nm"), "hname:'교과목명', required:'Y'");
f.addElement("lesson_hour", info.s("lesson_hour"), "hname:'기본수업시수', required:'Y'");
f.addElement("lesson_file", null, "hname:'교안파일'");
f.addElement("description", null, "hname:'강의설명'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	lesson.item("lesson_nm", f.get("lesson_nm"));
	lesson.item("lesson_type", f.get("lesson_type"));
	lesson.item("lesson_hour", f.getDouble("lesson_hour"));
	lesson.item("description", f.get("description"));
	if(!courseManagerBlock) lesson.item("manager_id", f.getInt("manager_id"));
	lesson.item("status", f.getInt("status"));

	if(null != f.getFileName("lesson_file")) {
		File f1 = f.saveFile("lesson_file");
		if(f1 != null) lesson.item("lesson_file", f.getFileName("lesson_file"));
		if(!"".equals(info.s("lesson_file"))) m.delFileRoot(m.getUploadPath(info.s("lesson_file")));
	}

	if(!lesson.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	if(!"pop".equals(ch)) {
		m.jsReplace("lesson_list.jsp?" + m.qs("id"), "parent");
		return;
	} else {
		out.print("<script>try { parent.opener.location.reload(); } catch(e) { } parent.window.close();</script>");
	}

}

//포맷팅
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));

//출력
p.setLayout(!"pop".equals(ch) ? "sysop" : "pop");
p.setBody("offline.lesson_insert");
p.setVar("p_title", "집합강의관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);
p.setVar("pop_block", "pop".equals(ch));

p.setLoop("lesson_types", m.arr2loop(lesson.offlineTypes));
p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>