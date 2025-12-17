<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 과제 > 피드백/채점 화면에서, 학생 피드백과 점수를 저장하고 성적에 반영해야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int homeworkId = m.ri("homework_id");
int courseUserId = m.ri("course_user_id");
double markingScore = m.parseDouble(m.rs("marking_score"));
String feedback = m.rs("feedback");

if(0 == courseId || 0 == homeworkId || 0 == courseUserId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, homework_id, course_user_id가 필요합니다.");
	result.print();
	return;
}
if(markingScore < 0 || 100 < markingScore) {
	result.put("rst_code", "1100");
	result.put("rst_message", "marking_score는 0~100 사이여야 합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
HomeworkDao homework = new HomeworkDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 과제 피드백을 수정할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet minfo = courseModule.query(
	" SELECT a.assign_score "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id AND h.site_id = " + siteId + " AND h.status != -1 "
	+ " WHERE a.course_id = " + courseId + " AND a.module = 'homework' AND a.module_id = " + homeworkId + " AND a.status = 1 "
);
if(!minfo.next()) {
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
if(null != feedback && -1 < feedback.indexOf("<img") && -1 < feedback.indexOf("data:image/") && -1 < feedback.indexOf("base64")) {
	result.put("rst_code", "1101");
	result.put("rst_message", "이미지는 첨부파일로 업로드해 주세요.");
	result.print();
	return;
}

String now = m.time("yyyyMMddHHmmss");
double score = Math.min(minfo.d("assign_score"), minfo.d("assign_score") * markingScore / 100.0);

DataSet huinfo = homeworkUser.find("homework_id = " + homeworkId + " AND course_user_id = " + courseUserId + " AND status = 1");
if(huinfo.next()) {
	//수정
	homeworkUser.item("submit_yn", "Y");
	homeworkUser.item("confirm_yn", "Y");
	homeworkUser.item("confirm_user_id", userId);
	homeworkUser.item("confirm_date", now);
	homeworkUser.item("marking_score", markingScore);
	homeworkUser.item("score", score);
	homeworkUser.item("feedback", feedback);
	homeworkUser.item("mod_date", now);
	if(!homeworkUser.update("homework_id = " + homeworkId + " AND course_user_id = " + courseUserId)) {
		result.put("rst_code", "2000");
		result.put("rst_message", "저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
} else {
	//왜: 오프라인 과제(또는 별도 제출경로)도 채점이 가능해야 하므로, 없으면 레코드를 생성합니다.
	homeworkUser.item("homework_id", homeworkId);
	homeworkUser.item("course_user_id", courseUserId);
	homeworkUser.item("course_id", courseId);
	homeworkUser.item("user_id", cuinfo.i("user_id"));
	homeworkUser.item("site_id", siteId);
	homeworkUser.item("subject", "");
	homeworkUser.item("content", "");
	homeworkUser.item("user_file", "");
	homeworkUser.item("marking_score", markingScore);
	homeworkUser.item("score", score);
	homeworkUser.item("feedback", feedback);
	homeworkUser.item("submit_yn", "Y");
	homeworkUser.item("confirm_yn", "Y");
	homeworkUser.item("confirm_user_id", userId);
	homeworkUser.item("confirm_date", now);
	homeworkUser.item("ip_addr", request.getRemoteAddr());
	homeworkUser.item("mod_date", now);
	homeworkUser.item("reg_date", now);
	homeworkUser.item("status", 1);
	if(!homeworkUser.insert()) {
		result.put("rst_code", "2000");
		result.put("rst_message", "저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
}

//성적 반영
courseUser.setCourseUserScore(courseUserId, "homework");

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", courseUserId);
result.print();

%>

