<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 과제 > 피드백 관리에서, 특정 학생의 추가 과제 목록을 조회합니다.
//- 학생이 재제출했는지 여부를 확인하여 교수자가 재평가할 수 있도록 합니다.

int courseId = m.ri("course_id");
int homeworkId = m.ri("homework_id");
int courseUserId = m.ri("course_user_id");

if(0 == courseId || 0 == homeworkId || 0 == courseUserId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, homework_id, course_user_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
HomeworkTaskDao homeworkTask = new HomeworkTaskDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 추가 과제를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet list = homeworkTask.find(
	"site_id = " + siteId + " AND course_id = " + courseId + " AND homework_id = " + homeworkId + " AND course_user_id = " + courseUserId + " AND status = 1"
	, "id, task, subject, content, submit_yn, submit_date, confirm_yn, confirm_date, feedback, reg_date"
	, "id DESC"
);

while(list.next()) {
	list.put("task_preview", list.s("task").length() > 50 ? list.s("task").substring(0, 50) + "..." : list.s("task"));
	list.put("submit_yn_label", "Y".equals(list.s("submit_yn")) ? "제출완료" : "미제출");
	list.put("confirm_yn_label", "Y".equals(list.s("confirm_yn")) ? "평가완료" : "평가대기");
	list.put("submit_date_conv", !"".equals(list.s("submit_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("submit_date")) : "-");
	list.put("confirm_date_conv", !"".equals(list.s("confirm_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("confirm_date")) : "-");
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	
	// 재제출 상태: submit_yn=Y이고 confirm_yn=N인 경우 재평가 필요
	boolean needReview = "Y".equals(list.s("submit_yn")) && !"Y".equals(list.s("confirm_yn"));
	list.put("need_review", needReview);
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", list);
result.print();

%>
