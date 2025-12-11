<%@ page contentType="application/json; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
Json result = new Json(out);
result.put("result", "error");
result.put("message", "올바른 접근이 아닙니다.");

//접근권한
if(!Menu.accessible(75, userId, userKind)) { result.put("message", "접근 권한이 없습니다."); result.print(); return; }

//기본키
int courseId = m.ri("cid");
int sectionId = m.ri("sid");
if(1 > courseId || 1 > sectionId) { result.put("message", "기본키는 반드시 지정해야 합니다."); result.print(); return; }

//객체
CourseSectionDao courseSection = new CourseSectionDao();

//폼체크
f.addElement("section_nm", null, "hname:'섹션명', required:'Y'");

//등록
if(m.isPost() && f.validate()) {	
	courseSection.item("section_nm", f.get("section_nm"));
	if(!courseSection.update("id = " + sectionId + " AND course_id = " + courseId + " AND site_id = " + siteId)) {
		result.put("message", "섹션명을 수정하는 중 오류가 발생했습니다.");
		return;
	} else {
		result.put("result", "success");
		result.put("message", "성공");
	}
}

result.print();

%>