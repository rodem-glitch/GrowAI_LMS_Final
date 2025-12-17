<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 과제 > 피드백 관리에서, 학생에게 "추가 과제"를 부여하고 이력을 남겨야 합니다.
//- LM_HOMEWORK_USER는 (homework_id, course_user_id) 1건만 저장되므로, 반복 부여/피드백은 LM_HOMEWORK_TASK에 누적합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int homeworkId = m.ri("homework_id");
int courseUserId = m.ri("course_user_id");
String task = m.rs("task");

if(0 == courseId || 0 == homeworkId || 0 == courseUserId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, homework_id, course_user_id가 필요합니다.");
	result.print();
	return;
}
if("".equals(task)) {
	result.put("rst_code", "1002");
	result.put("rst_message", "task(추가 과제 내용)가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
HomeworkDao homework = new HomeworkDao();
HomeworkTaskDao homeworkTask = new HomeworkTaskDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 추가 과제를 부여할 권한이 없습니다.");
		result.print();
		return;
	}
}

//과목에 배치된 과제인지 확인(왜: 다른 과목의 과제ID로 임의 호출되는 것을 막습니다)
if(0 >= courseModule.findCount("course_id = " + courseId + " AND module = 'homework' AND module_id = " + homeworkId + " AND status = 1")) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과제가 과목에 배치되어 있지 않습니다.");
	result.print();
	return;
}

DataSet cuinfo = courseUser.find("id = " + courseUserId + " AND course_id = " + courseId + " AND site_id = " + siteId + " AND status IN (1,3)");
if(!cuinfo.next()) {
	result.put("rst_code", "4041");
	result.put("rst_message", "해당 수강 정보가 없습니다.");
	result.print();
	return;
}

//왜: base64 이미지는 DB에 누적되면 용량 폭증/오류가 나기 쉽습니다.
if(-1 < task.indexOf("<img") && -1 < task.indexOf("data:image/") && -1 < task.indexOf("base64")) {
	result.put("rst_code", "1101");
	result.put("rst_message", "이미지는 첨부파일로 업로드해 주세요.");
	result.print();
	return;
}
int bytes = task.replace("\r\n", "\n").getBytes("UTF-8").length;
if(60000 < bytes) {
	result.put("rst_code", "1102");
	result.put("rst_message", "내용은 60000바이트를 초과할 수 없습니다. (현재 " + bytes + "바이트)");
	result.print();
	return;
}

//parent_id는 "직전 추가과제"를 가리키게 해서 타임라인을 만들 수 있게 합니다.
int parentId = 0;
try {
	int lastId = homeworkTask.getOneInt(
		"SELECT MAX(id) FROM " + homeworkTask.table
		+ " WHERE site_id = " + siteId + " AND course_id = " + courseId
		+ " AND homework_id = " + homeworkId + " AND course_user_id = " + courseUserId
		+ " AND status = 1"
	);
	if(0 < lastId) parentId = lastId;
} catch(Exception ignore) {}

String now = m.time("yyyyMMddHHmmss");
int newId = homeworkTask.getSequence();
homeworkTask.item("id", newId);
homeworkTask.item("site_id", siteId);
homeworkTask.item("course_id", courseId);
homeworkTask.item("homework_id", homeworkId);
homeworkTask.item("course_user_id", courseUserId);
homeworkTask.item("user_id", cuinfo.i("user_id"));
homeworkTask.item("parent_id", parentId);
homeworkTask.item("assign_user_id", userId);
homeworkTask.item("task", task);
homeworkTask.item("subject", "");
homeworkTask.item("content", "");
homeworkTask.item("submit_yn", "N");
homeworkTask.item("submit_date", "");
homeworkTask.item("confirm_yn", "N");
homeworkTask.item("confirm_user_id", 0);
homeworkTask.item("confirm_date", "");
homeworkTask.item("feedback", "");
homeworkTask.item("ip_addr", request.getRemoteAddr());
homeworkTask.item("mod_date", now);
homeworkTask.item("reg_date", now);
homeworkTask.item("status", 1);

if(!homeworkTask.insert()) {
	result.put("rst_code", "2000");
	result.put("rst_message", "추가 과제 저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", newId);
result.print();

%>

