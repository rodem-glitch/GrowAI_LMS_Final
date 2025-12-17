<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목 소개/학습목표 같은 텍스트는 운영 중에도 수정될 수 있으므로 저장 API가 필요합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
	result.print();
	return;
}

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();

if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목 정보를 수정할 권한이 없습니다.");
		result.print();
		return;
	}
}

f.addElement("content1", "", "hname:'과목소개', allowhtml:'Y'");
f.addElement("content2", "", "hname:'학습목표', allowhtml:'Y'");

String content1 = f.get("content1");
String content2 = f.get("content2");

course.item("content1_title", "과목소개");
course.item("content1", content1);
course.item("content2_title", "학습목표");
course.item("content2", content2);
course.item("mod_date", m.time("yyyyMMddHHmmss"));

if(!course.update("id = " + courseId + " AND site_id = " + siteId + " AND status != -1")) {
	result.put("rst_code", "2000");
	result.put("rst_message", "저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", courseId);
result.print();

%>

