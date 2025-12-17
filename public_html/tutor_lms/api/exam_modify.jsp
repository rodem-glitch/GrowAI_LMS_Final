<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 시험 탭에서 시험 정보를 수정해야, 운영 일정/배점이 실제 DB에 반영됩니다.

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
ExamDao exam = new ExamDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 시험 정보를 수정할 권한이 없습니다.");
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

DataSet einfo = exam.find("id = " + examId + " AND site_id = " + siteId + " AND status != -1");
if(!einfo.next()) {
	result.put("rst_code", "4042");
	result.put("rst_message", "시험 정보가 없습니다.");
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
f.addElement("questionCount", einfo.i("question_cnt"), "hname:'문제 수', option:'number'");
f.addElement("totalScore", minfo.i("assign_score"), "hname:'배점', option:'number'");
f.addElement("allowRetake", minfo.s("retry_yn"), "hname:'재시험 허용'");
f.addElement("showResults", minfo.s("result_yn"), "hname:'결과 공개'");
f.addElement("onoff_type", einfo.s("onoff_type"), "hname:'온오프라인구분'");

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
String onoffType = !"".equals(f.get("onoff_type")) ? f.get("onoff_type") : einfo.s("onoff_type");

//시험 수정
exam.item("exam_nm", title);
exam.item("onoff_type", onoffType);
exam.item("exam_time", examTimeMin);
exam.item("content", f.get("description"));
exam.item("question_cnt", questionCnt);
exam.item("retake_yn", retakeYn);
exam.item("permission_number", "Y".equals(retakeYn) ? 1 : 0);
exam.item("mod_date", m.time("yyyyMMddHHmmss"));
if(!exam.update("id = " + examId + " AND site_id = " + siteId + " AND status != -1")) {
	result.put("rst_code", "2000");
	result.put("rst_message", "시험 수정 중 오류가 발생했습니다.");
	result.print();
	return;
}

//과목 배치 수정
courseModule.item("module_nm", title);
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
courseModule.item("result_yn", resultYn);
if(!courseModule.update("course_id = " + courseId + " AND module = 'exam' AND module_id = " + examId + " AND status = 1")) {
	result.put("rst_code", "2001");
	result.put("rst_message", "과목 배치 수정 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", examId);
result.print();

%>

