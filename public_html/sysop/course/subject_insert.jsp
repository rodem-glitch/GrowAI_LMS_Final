<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(79, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SubjectDao subject = new SubjectDao();

//폼체크
f.addElement("course_nm", null, "hname:'과정명', required:'Y'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	subject.item("site_id", siteId);
	subject.item("course_nm", f.get("course_nm"));
	subject.item("reg_date", m.time("yyyyMMddHHmmss"));
	subject.item("status", f.get("status"));
	if(!subject.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("subject_list.jsp", "parent");
	return;
}

//출력
p.setBody("course.subject_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(subject.statusList));
p.display();

%>