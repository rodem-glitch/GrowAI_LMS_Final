<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 시험 > 채점 화면에서, 학생 점수를 저장하면 즉시 성적/수료 계산에 반영돼야 합니다.
//- 그래서 LM_EXAM_USER를 업데이트하고, LM_COURSE_USER 점수(시험)를 재계산합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int examId = m.ri("exam_id");
int courseUserId = m.ri("course_user_id");
double markingScore = m.parseDouble(m.rs("marking_score"));

if(0 == courseId || 0 == examId || 0 == courseUserId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, exam_id, course_user_id가 필요합니다.");
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
ExamUserDao examUser = new ExamUserDao();
ExamDao exam = new ExamDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 시험 점수를 수정할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet minfo = courseModule.query(
	" SELECT a.assign_score "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.site_id = " + siteId + " AND e.status != -1 "
	+ " WHERE a.course_id = " + courseId + " AND a.module = 'exam' AND a.module_id = " + examId + " AND a.status = 1 "
);
if(!minfo.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 시험이 과목에 배치되어 있지 않습니다.");
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

String now = m.time("yyyyMMddHHmmss");
double score = Math.min(minfo.d("assign_score"), minfo.d("assign_score") * markingScore / 100.0);

DataSet euinfo = examUser.find("exam_id = " + examId + " AND course_user_id = " + courseUserId + " AND exam_step = 1 AND status = 1");
if(euinfo.next()) {
	//수정
	examUser.item("submit_yn", "Y");
	if("".equals(euinfo.s("submit_date"))) examUser.item("submit_date", now);
	examUser.item("confirm_yn", "Y");
	examUser.item("confirm_user_id", userId);
	examUser.item("confirm_date", now);
	examUser.item("marking_score", markingScore);
	examUser.item("score", score);
	examUser.item("mod_date", now);
	if(!examUser.update("exam_id = " + examId + " AND course_user_id = " + courseUserId + " AND exam_step = 1")) {
		result.put("rst_code", "2000");
		result.put("rst_message", "점수 저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
} else {
	//왜: 오프라인 시험은 학생이 온라인으로 응시하지 않을 수 있으므로, 채점 시점에 응시 레코드를 자동으로 만들어 줍니다.
	examUser.item("exam_id", examId);
	examUser.item("course_user_id", courseUserId);
	examUser.item("exam_step", 1);
	examUser.item("course_id", courseId);
	examUser.item("user_id", cuinfo.i("user_id"));
	examUser.item("site_id", siteId);
	examUser.item("choice_yn", "Y");
	examUser.item("score", score);
	examUser.item("marking_score", markingScore);
	examUser.item("feedback", "");
	examUser.item("duration", 0);
	examUser.item("ba_cnt", 0);
	examUser.item("submit_yn", "Y");
	examUser.item("confirm_yn", "Y");
	examUser.item("confirm_user_id", userId);
	examUser.item("confirm_date", now);
	examUser.item("submit_date", now);
	examUser.item("apply_cnt", 1);
	examUser.item("apply_date", now);
	examUser.item("onload_date", now);
	examUser.item("unload_date", now);
	examUser.item("ip_addr", request.getRemoteAddr());
	examUser.item("mod_date", now);
	examUser.item("reg_date", now);
	examUser.item("status", 1);
	if(!examUser.insert()) {
		result.put("rst_code", "2000");
		result.put("rst_message", "점수 저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
}

//성적 반영
courseUser.setCourseUserScore(courseUserId, "exam");

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", courseUserId);
result.print();

%>

