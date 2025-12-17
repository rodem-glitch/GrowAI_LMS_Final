<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 시험 등록(모달)에서, 시험(LM_EXAM)과 과목 배치(LM_COURSE_MODULE)를 함께 생성해야 합니다.
//- 그래야 새로고침해도 목록/제출현황/채점 데이터가 DB에 남아 "실사용"이 됩니다.

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
CourseModuleDao courseModule = new CourseModuleDao();
ExamDao exam = new ExamDao();

//왜: 교수자는 본인 과목만 등록, 관리자는 전체 과목에 등록할 수 있어야 합니다.
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

//필수값
f.addElement("title", null, "hname:'시험 제목', required:'Y'");
f.addElement("examDate", null, "hname:'시험 날짜', required:'Y'");
f.addElement("examTime", null, "hname:'시험 시작시간', required:'Y'");
f.addElement("duration", 60, "hname:'시험시간(분)', required:'Y', option:'number'");

//선택값
f.addElement("description", "", "hname:'시험 설명', allowhtml:'Y'");
f.addElement("questionCount", 0, "hname:'문제 수', option:'number'");
f.addElement("totalScore", 100, "hname:'배점', option:'number'");
f.addElement("allowRetake", "false", "hname:'재시험 허용'");
f.addElement("showResults", "true", "hname:'결과 공개'");
f.addElement("onoff_type", "F", "hname:'온오프라인구분'"); //왜: 현재 tutor 화면은 문제은행 연동이 없어서, 기본은 오프라인(수기채점)으로 둡니다.

if(!f.validate()) {
	result.put("rst_code", "1000");
	result.put("rst_message", "필수값이 누락되었습니다.");
	result.print();
	return;
}

String title = f.get("title").trim();
int examTimeMin = f.getInt("duration");
int questionCnt = Math.max(0, f.getInt("questionCount"));
int assignScore = Math.max(0, f.getInt("totalScore"));

//왜: 날짜/시간 포맷이 깨지면 LM_COURSE_MODULE 시작/종료일 저장이 꼬여서, 조회/정렬이 틀어질 수 있습니다.
String startYmd = m.time("yyyyMMdd", f.get("examDate"));
String startHm = f.get("examTime");
String startH = (startHm != null && 5 <= startHm.length()) ? startHm.substring(0, 2) : "00";
String startM = (startHm != null && 5 <= startHm.length()) ? startHm.substring(3, 5) : "00";
String startDateTime = startYmd + startH + startM + "00";

String endDateTime = startDateTime;
try {
	java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyyMMddHHmmss");
	java.util.Date d = sdf.parse(startDateTime);
	java.util.Calendar cal = java.util.Calendar.getInstance();
	cal.setTime(d);
	cal.add(java.util.Calendar.MINUTE, Math.max(0, examTimeMin));
	endDateTime = sdf.format(cal.getTime());
} catch(Exception ignore) {}

String retakeYn = ("true".equalsIgnoreCase(f.get("allowRetake")) || "Y".equalsIgnoreCase(f.get("allowRetake"))) ? "Y" : "N";
String resultYn = ("false".equalsIgnoreCase(f.get("showResults")) || "N".equalsIgnoreCase(f.get("showResults"))) ? "N" : "Y";
String onoffType = !"".equals(f.get("onoff_type")) ? f.get("onoff_type") : "F";

//시험(LM_EXAM) 생성
int newId = exam.getSequence();
exam.item("id", newId);
exam.item("site_id", siteId);
exam.item("category_id", 0);
exam.item("onoff_type", onoffType);
exam.item("exam_nm", title);
exam.item("range_idx", "");
exam.item("exam_time", examTimeMin);
exam.item("content", f.get("description"));
exam.item("question_cnt", questionCnt);

//왜: 문제은행/난이도 분배를 tutor 화면에서 아직 다루지 않으므로, 최소값(0)로 안전하게 채웁니다.
exam.item("mcnt1", questionCnt);
exam.item("mcnt2", 0); exam.item("mcnt3", 0); exam.item("mcnt4", 0); exam.item("mcnt5", 0); exam.item("mcnt6", 0);
exam.item("tcnt1", 0); exam.item("tcnt2", 0); exam.item("tcnt3", 0); exam.item("tcnt4", 0); exam.item("tcnt5", 0); exam.item("tcnt6", 0);
exam.item("assign1", questionCnt > 0 ? Math.max(1, 100 / questionCnt) : 0);
exam.item("assign2", 0); exam.item("assign3", 0); exam.item("assign4", 0); exam.item("assign5", 0); exam.item("assign6", 0);

exam.item("shuffle_yn", "Y");
exam.item("auto_complete_yn", "N");
exam.item("retake_yn", retakeYn);
exam.item("permission_number", "Y".equals(retakeYn) ? 1 : 0);
exam.item("manager_id", userId);
exam.item("reg_date", m.time("yyyyMMddHHmmss"));
exam.item("status", 1);

if(!exam.insert()) {
	result.put("rst_code", "2000");
	result.put("rst_message", "시험 저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

//과목 배치(LM_COURSE_MODULE) 생성
courseModule.item("course_id", courseId);
courseModule.item("site_id", siteId);
courseModule.item("module", "exam");
courseModule.item("module_id", newId);
courseModule.item("module_nm", title);
courseModule.item("parent_id", 0);
courseModule.item("item_type", "R");
courseModule.item("assign_score", assignScore);
courseModule.item("apply_type", "1");
courseModule.item("start_day", 0);
courseModule.item("period", 0);
courseModule.item("start_date", startDateTime);
courseModule.item("end_date", endDateTime);
courseModule.item("chapter", 0);
courseModule.item("retry_yn", retakeYn);
courseModule.item("retry_score", 0);
courseModule.item("retry_cnt", "Y".equals(retakeYn) ? 1 : 0);
courseModule.item("review_yn", "N");
courseModule.item("result_yn", resultYn);
courseModule.item("status", 1);

if(!courseModule.insert()) {
	//왜: 시험은 생성됐는데 과목 배치가 실패하면 화면에서 찾을 수 없는 "유령 시험"이 생깁니다. 그래서 바로 soft-delete 합니다.
	exam.item("status", -1);
	exam.update("id = " + newId);

	result.put("rst_code", "2001");
	result.put("rst_message", "과목 배치 저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", newId);
result.print();

%>

