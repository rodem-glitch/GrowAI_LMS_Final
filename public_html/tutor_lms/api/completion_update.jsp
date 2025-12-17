<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목관리 > 수료관리 탭에서, 선택한 학생을 수료/합격 처리하거나 마감(close) 처리해야 합니다.
//- sysop의 CourseUserDao.completeUser 로직을 활용해 동일한 판정이 나오도록 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
String action = m.rs("action"); //complete_y, complete_n, close_y, close_n
String idx = m.rs("course_user_ids"); //콤마 구분

if(0 == courseId || "".equals(action) || "".equals(idx)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id, action, course_user_ids가 필요합니다.");
	result.print();
	return;
}

//왜: IN (...)에 들어가는 값은 숫자/콤마만 허용해서 SQL 인젝션을 막습니다.
if(!idx.matches("^[0-9,]+$")) {
	result.put("rst_code", "1002");
	result.put("rst_message", "course_user_ids 형식이 올바르지 않습니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//권한
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 수료처리를 할 권한이 없습니다.");
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

String now = m.time("yyyyMMddHHmmss");
int success = 0;

DataSet culist = courseUser.find("site_id = " + siteId + " AND course_id = " + courseId + " AND status IN (1,3) AND id IN (" + idx + ")");
while(culist.next()) {
	int cuid = culist.i("id");

	if("complete_y".equals(action)) {
		if(1 == courseUser.completeUser(cuid)) success++;
	} else if("complete_n".equals(action)) {
		courseUser.item("complete_yn", "");
		courseUser.item("complete_status", "");
		courseUser.item("complete_no", "");
		courseUser.item("complete_date", "");
		courseUser.item("fail_reason", "");
		courseUser.item("mod_date", now);
		if(courseUser.update("id = " + cuid + " AND close_yn = 'N'")) success++;
	} else if("close_y".equals(action)) {
		//왜: 종료(close)는 보통 수료 판정까지 같이 필요합니다.
		if("".equals(culist.s("complete_status"))) courseUser.completeUser(cuid);
		courseUser.item("close_yn", "Y");
		courseUser.item("close_date", now);
		courseUser.item("close_user_id", userId);
		courseUser.item("mod_date", now);
		if(courseUser.update("id = " + cuid + "")) success++;
	} else if("close_n".equals(action)) {
		courseUser.item("close_yn", "N");
		courseUser.item("close_date", "");
		courseUser.item("close_user_id", 0);
		courseUser.item("mod_date", now);
		if(courseUser.update("id = " + cuid + "")) success++;
	}
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", success);
result.print();

%>

