<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 강의목차에서 레슨(차시)을 제거할 수 있어야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int lessonId = m.ri("lesson_id");
if(0 == courseId || 0 == lessonId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id와 lesson_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseLessonDao courseLesson = new CourseLessonDao();

if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 강의목차를 수정할 권한이 없습니다.");
		result.print();
		return;
	}
}

courseLesson.item("status", -1);
if(!courseLesson.update("course_id = " + courseId + " AND lesson_id = " + lessonId + " AND status = 1")) {
	result.put("rst_code", "2000");
	result.put("rst_message", "레슨 제거 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", lessonId);
result.print();

%>

