<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 피드백 관리에서 학생의 "추가 과제" 제출 내용을 확인한 후, 교수자가 "확인(평가완료)" 처리를 하고 피드백을 남깁니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int taskId = m.ri("task_id");
int courseId = m.ri("course_id");
String feedback = m.rs("feedback");

if(0 == taskId || 0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "task_id, course_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
HomeworkTaskDao homeworkTask = new HomeworkTaskDao();

//권한 확인
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 추가 과제를 평가할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet info = homeworkTask.find("id = " + taskId + " AND course_id = " + courseId + " AND status = 1");
if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 추가 과제 정보를 찾을 수 없습니다.");
	result.print();
	return;
}

String now = m.time("yyyyMMddHHmmss");
homeworkTask.item("confirm_yn", "Y");
homeworkTask.item("confirm_user_id", userId);
homeworkTask.item("confirm_date", now);
homeworkTask.item("feedback", feedback);
homeworkTask.item("mod_date", now);

if(!homeworkTask.update("id = " + taskId)) {
	result.put("rst_code", "2000");
	result.put("rst_message", "추가 과제 정보 업데이트 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.print();

%>
