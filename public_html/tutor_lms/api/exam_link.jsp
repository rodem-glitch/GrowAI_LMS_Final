<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 시험관리에서 생성한 시험(LM_EXAM)을 과목에 연결(LM_COURSE_MODULE)만 합니다.
//- 기존 exam_insert.jsp와 달리, 시험을 복사하지 않고 기존 시험을 그대로 사용합니다.

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
	result.put("rst_message", "course_id와 exam_id가 필요합니다.");
	result.print();
	return;
}

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
ExamDao exam = new ExamDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목에 시험을 등록할 권한이 없습니다.");
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

DataSet einfo = exam.find("id = " + examId + " AND site_id = " + siteId + " AND status != -1");
if(!einfo.next()) {
	result.put("rst_code", "4041");
	result.put("rst_message", "시험 정보가 없습니다.");
	result.print();
	return;
}

// 이미 연결된 시험인지 확인
if(0 < courseModule.findCount("course_id = " + courseId + " AND module = 'exam' AND module_id = " + examId + " AND status = 1")) {
	result.put("rst_code", "4042");
	result.put("rst_message", "이미 등록된 시험입니다.");
	result.print();
	return;
}

// 선택적 파라미터
String startDate = m.rs("start_date");
String endDate = m.rs("end_date");
int assignScore = m.ri("assign_score", 100);
String retryYn = "Y".equals(m.rs("retry_yn")) ? "Y" : "N";
String resultYn = "N".equals(m.rs("result_yn")) ? "N" : "Y";

// 기본값 처리
if("".equals(startDate)) startDate = m.time("yyyyMMdd") + "090000";
if("".equals(endDate)) endDate = m.addDate("D", 7, startDate.substring(0, 8), "yyyyMMdd") + "180000";

// 과목 배치(LM_COURSE_MODULE) 생성 - 기존 시험과 연결만 함
courseModule.item("course_id", courseId);
courseModule.item("site_id", siteId);
courseModule.item("module", "exam");
courseModule.item("module_id", examId);
courseModule.item("module_nm", einfo.s("exam_nm"));
courseModule.item("parent_id", 0);
courseModule.item("item_type", "R");
courseModule.item("assign_score", assignScore);
courseModule.item("apply_type", "1");
courseModule.item("start_day", 0);
courseModule.item("period", 0);
courseModule.item("start_date", startDate);
courseModule.item("end_date", endDate);
courseModule.item("chapter", 0);
courseModule.item("retry_yn", retryYn);
courseModule.item("retry_score", 0);
courseModule.item("retry_cnt", "Y".equals(retryYn) ? 1 : 0);
courseModule.item("review_yn", "N");
courseModule.item("result_yn", resultYn);
courseModule.item("status", 1);

if(!courseModule.insert()) {
	result.put("rst_code", "2001");
	result.put("rst_message", "과목에 시험 연결 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", examId);
result.print();

%>
