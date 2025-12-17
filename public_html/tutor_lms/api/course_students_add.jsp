<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목개설(CreateSubjectWizard) 또는 수강생 관리에서 선택한 학습자를 실제 수강생(LM_COURSE_USER)으로 등록해야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
String userIdsRaw = m.rs("user_ids"); //예: "12,34,56"
if(0 == courseId || "".equals(userIdsRaw)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id와 user_ids가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

//권한: 교수자는 본인 과목(주강사)만, 관리자는 전체
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 수강생을 등록할 권한이 없습니다.");
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

int inserted = 0;
int skipped = 0;
String[] parts = m.split(",", userIdsRaw);
for(int i = 0; i < parts.length; i++) {
	int targetUserId = m.parseInt(parts[i]);
	if(targetUserId <= 0) continue;

	//중복 방지
	if(0 < courseUser.findCount("course_id = " + courseId + " AND user_id = " + targetUserId + " AND status NOT IN (-1, -4)")) {
		skipped++;
		continue;
	}

	if(courseUser.addUser(cinfo, targetUserId, 1)) inserted++;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", inserted);
result.put("rst_skipped", skipped);
result.print();

%>

