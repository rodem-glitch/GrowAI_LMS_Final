<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 시험 탭에서, 더 이상 사용하지 않는 시험을 과목에서 제거(배치 해제)해야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int examId = m.ri("exam_id");
if(0 == courseId || 0 == examId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, exam_id가 필요합니다.");
	result.print();
	return;
}

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 시험을 삭제할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + " AND status != -1");
if(!cinfo.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과목이 없습니다.");
	result.print();
	return;
}

DataSet minfo = courseModule.find("course_id = " + courseId + " AND module = 'exam' AND module_id = " + examId + " AND status = 1");
if(!minfo.next()) {
	result.put("rst_code", "4041");
	result.put("rst_message", "해당 시험이 과목에 배치되어 있지 않습니다.");
	result.print();
	return;
}

//왜: 응시/채점 내역이 있으면 배치만 지워도 데이터가 끊기므로, 안전하게 막습니다.
if(0 < examUser.findCount("exam_id = " + examId + " AND course_id = " + courseId + " AND status = 1")) {
	result.put("rst_code", "4090");
	result.put("rst_message", "응시/채점 내역이 있어 삭제할 수 없습니다.");
	result.print();
	return;
}

//배치 삭제
if(!courseModule.delete("course_id = " + courseId + " AND module = 'exam' AND module_id = " + examId + "")) {
	result.put("rst_code", "2000");
	result.put("rst_message", "삭제 중 오류가 발생했습니다.");
	result.print();
	return;
}

//왜: 다른 과목에서 쓰지 않는 시험이면 soft-delete로 정리합니다.
try {
	if(0 >= courseModule.findCount("module = 'exam' AND module_id = " + examId + "")) {
		exam.item("status", -1);
		exam.update("id = " + examId + " AND site_id = " + siteId);
	}
} catch(Exception ignore) {}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", examId);
result.print();

%>

