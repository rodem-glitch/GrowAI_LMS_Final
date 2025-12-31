<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 교수자가 제출된 시험 응시를 취소할 수 있어야 합니다.
//- 응시 레코드/결과를 삭제하고 성적을 즉시 재계산합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int examId = m.ri("exam_id");
int courseUserId = m.ri("course_user_id");

if(0 == courseId || 0 == examId || 0 == courseUserId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, exam_id, course_user_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseUserDao courseUser = new CourseUserDao();
ExamUserDao examUser = new ExamUserDao();
ExamResultDao examResult = new ExamResultDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 시험 응시를 취소할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet cuinfo = courseUser.find("id = " + courseUserId + " AND course_id = " + courseId + " AND site_id = " + siteId + " AND status IN (1,3)");
if(!cuinfo.next()) {
	result.put("rst_code", "4041");
	result.put("rst_message", "해당 수강 정보가 없습니다.");
	result.print();
	return;
}

//왜: 응시 기록이 없으면 취소할 대상이 없으므로 안내만 합니다.
DataSet euinfo = examUser.find("exam_id = " + examId + " AND course_user_id = " + courseUserId + " AND exam_step = 1 AND status = 1");
if(!euinfo.next()) {
	result.put("rst_code", "4042");
	result.put("rst_message", "해당 응시 정보가 없습니다.");
	result.print();
	return;
}

//삭제-결과
if(!examResult.delete("exam_id = " + examId + " AND course_user_id = " + courseUserId)) {
	result.put("rst_code", "2000");
	result.put("rst_message", "응시 취소 중 오류가 발생했습니다.");
	result.print();
	return;
}

//삭제-응시
if(!examUser.delete("exam_id = " + examId + " AND course_user_id = " + courseUserId + " AND exam_step = 1")) {
	result.put("rst_code", "2000");
	result.put("rst_message", "응시 취소 중 오류가 발생했습니다.");
	result.print();
	return;
}

//성적 반영
courseUser.setCourseUserScore(courseUserId, "exam");

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", courseUserId);
result.print();

%>
