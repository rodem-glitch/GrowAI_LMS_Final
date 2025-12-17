<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 차시(섹션)를 삭제할 수 있어야 합니다.
//- 섹션을 삭제해도 레슨(차시) 데이터는 유지되도록, 연결된 레슨은 section_id=0(기본)으로 돌립니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int sectionId = m.ri("section_id");
if(0 == courseId || 0 == sectionId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id와 section_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseSectionDao courseSection = new CourseSectionDao();
CourseLessonDao courseLesson = new CourseLessonDao();

if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 강의목차를 수정할 권한이 없습니다.");
		result.print();
		return;
	}
}

courseSection.item("status", -1);
courseSection.update("id = " + sectionId + " AND course_id = " + courseId + " AND site_id = " + siteId + " AND status = 1");

//연결된 레슨은 기본 섹션으로 이동
courseLesson.execute(
	"UPDATE " + courseLesson.table + " SET section_id = 0 "
	+ " WHERE course_id = " + courseId + " AND section_id = " + sectionId + " AND status = 1"
);

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", sectionId);
result.print();

%>

