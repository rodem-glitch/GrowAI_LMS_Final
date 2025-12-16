<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 특정 과정(프로그램)에 소속된 과목 목록을 불러와서, 화면에서 묶음(연계) 상태를 보여주기 위함입니다.

int programId = m.ri("program_id");
if(0 == programId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "program_id가 필요합니다.");
	result.print();
	return;
}

SubjectDao subject = new SubjectDao();
CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();

//왜: 교수자는 본인 과정만, 관리자는 전체 과정의 과목 목록을 조회할 수 있어야 합니다.
String whereOwner = !isAdmin ? (" AND user_id = " + userId + " ") : "";
DataSet pinfo = subject.find("id = " + programId + " AND site_id = " + siteId + " AND status != -1 " + whereOwner);
if(!pinfo.next()) {
	result.put("rst_code", "4032");
	result.put("rst_message", "해당 과정이 없거나 접근 권한이 없습니다.");
	result.print();
	return;
}

String joinTutor = "";
if(!isAdmin) {
	//교수자는 "내 과목(주강사)"만 보이게 제한
	joinTutor = " INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ";
}

DataSet list = course.query(
	" SELECT c.id, c.course_cd, c.course_nm, c.year, c.step, c.course_type, c.onoff_type, c.study_sdate, c.study_edate, c.status "
	+ " FROM " + course.table + " c "
	+ joinTutor
	+ " WHERE c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' AND c.subject_id = " + programId + " "
	+ " ORDER BY c.id DESC "
);

while(list.next()) {
	String courseId = !"".equals(list.s("course_cd")) ? list.s("course_cd") : (list.i("id") + "");
	list.put("course_id_conv", courseId);
	list.put("subject_nm_conv", m.cutString(list.s("course_nm"), 100));
	list.put("study_sdate_conv", !"".equals(list.s("study_sdate")) ? m.time("yyyy.MM.dd", list.s("study_sdate")) : "");
	list.put("study_edate_conv", !"".equals(list.s("study_edate")) ? m.time("yyyy.MM.dd", list.s("study_edate")) : "");
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_program_id", programId);
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>
