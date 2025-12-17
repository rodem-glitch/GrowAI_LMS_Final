<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- React 화면에서 "수료증/합격증 출력" 버튼을 누르면, 새 창으로 인쇄용 페이지를 열어야 합니다.
//- 그래서 인쇄 URL을 안전하게 발급(권한 검사 포함)하는 API를 제공합니다.

int courseUserId = m.ri("course_user_id");
String certType = m.rs("type"); //C(수료), P(합격)
if(0 == courseUserId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_user_id가 필요합니다.");
	result.print();
	return;
}
if(!"P".equals(certType)) certType = "C";

CourseUserDao courseUser = new CourseUserDao();
CourseTutorDao courseTutor = new CourseTutorDao();

DataSet cuinfo = courseUser.find("id = " + courseUserId + " AND site_id = " + siteId + " AND status IN (1,3)");
if(!cuinfo.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "수강 정보가 없습니다.");
	result.print();
	return;
}

int courseId = cuinfo.i("course_id");
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 증명서를 발급할 권한이 없습니다.");
		result.print();
		return;
	}
}

//인쇄용 페이지 URL
String printUrl = "/tutor_lms/certificate_template.jsp?cuid=" + courseUserId + "&type=" + certType;

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", printUrl);
result.print();

%>

