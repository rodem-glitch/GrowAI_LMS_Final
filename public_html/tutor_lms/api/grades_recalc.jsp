<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 시험/과제 채점 후 "총점/수료기준"을 다시 계산해야 하는 상황이 많습니다.
//- sysop의 성적처리 로직(CourseUserDao.updateUserScore)을 그대로 활용해, 과목 단위로 재계산 API를 제공합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int courseUserId = m.ri("course_user_id"); //선택(0이면 전체)
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
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
		result.put("rst_message", "해당 과목의 성적을 처리할 권한이 없습니다.");
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

String where = "site_id = " + siteId + " AND course_id = " + courseId + " AND status IN (1,3)";
if(0 < courseUserId) where += " AND id = " + courseUserId;

DataSet culist = courseUser.find(where, "id, etc_score");
int success = 0;
while(culist.next()) {
	DataSet tmp = new DataSet();
	tmp.addRow();
	tmp.put("id", culist.i("id"));
	tmp.put("etc_score", culist.d("etc_score"));
	tmp.first();

	cinfo.first();
	if(courseUser.updateUserScore(tmp, cinfo)) success++;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", success);
result.print();

%>

