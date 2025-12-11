<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int courseId = m.ri("cid");
if(1 > courseId) { m.jsAlert("기본키는 반드시 지정해야 합니다."); m.js("parent.CloseLayer();"); return; }

//객체
CourseSectionDao courseSection = new CourseSectionDao();

//폼체크
f.addElement("section_nm", null, "hname:'섹션명', required:'Y'");

//등록
if(m.isPost() && f.validate()) {
	
	courseSection.item("course_id", courseId);
	courseSection.item("site_id", siteId);
	courseSection.item("section_nm", f.get("section_nm"));
	courseSection.item("status", 1);

	if(!courseSection.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsReplace("../course/course_lesson.jsp?" + m.qs(), "parent");
	m.js("parent.CloseLayer();");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("course.section_insert");
p.setVar("p_title", "섹션추가");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.display();

%>