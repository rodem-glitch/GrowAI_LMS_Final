<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 강의목차에서 "차시(섹션)"를 추가할 수 있어야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
String sectionNm = m.rs("section_nm").trim();
if(0 == courseId || "".equals(sectionNm)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id와 section_nm이 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseSectionDao courseSection = new CourseSectionDao();

if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 강의목차를 수정할 권한이 없습니다.");
		result.print();
		return;
	}
}

int newId = courseSection.getSequence();
courseSection.item("id", newId);
courseSection.item("course_id", courseId);
courseSection.item("site_id", siteId);
courseSection.item("section_nm", sectionNm);
courseSection.item("status", 1);
if(!courseSection.insert()) {
	result.put("rst_code", "2000");
	result.put("rst_message", "차시 추가 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", newId);
result.print();

%>

