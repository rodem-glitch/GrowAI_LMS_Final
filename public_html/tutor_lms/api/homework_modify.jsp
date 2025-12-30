<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 과제 탭에서 과제 정보를 수정해야, 마감일/배점이 실제 DB에 반영됩니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int homeworkId = m.ri("homework_id");
if(0 == courseId || 0 == homeworkId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, homework_id가 필요합니다.");
	result.print();
	return;
}

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
HomeworkDao homework = new HomeworkDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 과제 정보를 수정할 권한이 없습니다.");
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

DataSet minfo = courseModule.find("course_id = " + courseId + " AND module = 'homework' AND module_id = " + homeworkId + " AND status = 1");
if(!minfo.next()) {
	result.put("rst_code", "4041");
	result.put("rst_message", "해당 과제가 과목에 배치되어 있지 않습니다.");
	result.print();
	return;
}

DataSet hinfo = homework.find("id = " + homeworkId + " AND site_id = " + siteId + " AND status != -1");
if(!hinfo.next()) {
	result.put("rst_code", "4042");
	result.put("rst_message", "과제 정보가 없습니다.");
	result.print();
	return;
}

//필수값
f.addElement("title", null, "hname:'과제 제목', required:'Y'");
f.addElement("description", hinfo.s("content"), "hname:'과제 설명', allowhtml:'Y'");
f.addElement("dueDate", null, "hname:'마감 날짜', required:'Y'");
f.addElement("dueTime", null, "hname:'마감 시간', required:'Y'");
f.addElement("totalScore", minfo.i("assign_score"), "hname:'배점', required:'Y', option:'number'");
f.addElement("onoff_type", hinfo.s("onoff_type"), "hname:'온오프라인구분'");

if(!f.validate()) {
	result.put("rst_code", "1000");
	result.put("rst_message", "필수값이 누락되었습니다.");
	result.print();
	return;
}

String title = f.get("title").trim();
String content = f.get("description");
int assignScore = Math.max(0, f.getInt("totalScore"));
String onoffType = !"".equals(f.get("onoff_type")) ? f.get("onoff_type") : hinfo.s("onoff_type");

if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
	result.put("rst_code", "1101");
	result.put("rst_message", "이미지는 첨부파일로 업로드해 주세요.");
	result.print();
	return;
}
int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
if(60000 < bytes) {
	result.put("rst_code", "1102");
	result.put("rst_message", "내용은 60000바이트를 초과할 수 없습니다. (현재 " + bytes + "바이트)");
	result.print();
	return;
}

String endYmd = m.time("yyyyMMdd", f.get("dueDate"));
String endHm = f.get("dueTime");
String endH = (endHm != null && 5 <= endHm.length()) ? endHm.substring(0, 2) : "23";
String endM = (endHm != null && 5 <= endHm.length()) ? endHm.substring(3, 5) : "59";
String endDateTime = endYmd + endH + endM + "59";

//과제 수정
homework.item("homework_nm", title);
homework.item("onoff_type", onoffType);
homework.item("content", content);
homework.item("mod_date", m.time("yyyyMMddHHmmss"));
if(!homework.update("id = " + homeworkId + " AND site_id = " + siteId + " AND status != -1")) {
	result.put("rst_code", "2000");
	result.put("rst_message", "과제 수정 중 오류가 발생했습니다.");
	result.print();
	return;
}

//과목 배치 수정
courseModule.item("module_nm", title);
courseModule.item("assign_score", assignScore);
courseModule.item("apply_type", "1");
courseModule.item("end_date", endDateTime);
if(!courseModule.update("course_id = " + courseId + " AND module = 'homework' AND module_id = " + homeworkId + " AND status = 1")) {
	result.put("rst_code", "2001");
	result.put("rst_message", "과목 배치 수정 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", homeworkId);
result.print();

%>

