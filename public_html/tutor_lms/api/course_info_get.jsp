<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과목정보 탭에서 과목 소개/학습목표 같은 상세 정보를 DB에서 읽어와 보여줘야 합니다.

int courseId = m.ri("course_id");
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
	result.print();
	return;
}

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
SubjectDao subject = new SubjectDao();

if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목 정보를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet info = course.query(
	" SELECT c.* "
	+ " , s.course_nm program_nm, s.start_date program_start_date, s.end_date program_end_date "
	+ " , (SELECT COUNT(*) FROM " + new CourseUserDao().table + " cu WHERE cu.course_id = c.id AND cu.site_id = " + siteId + " AND cu.status NOT IN (-1, -4)) student_cnt "
	+ " FROM " + course.table + " c "
	+ " LEFT JOIN " + subject.table + " s ON s.id = c.subject_id AND s.site_id = " + siteId + " AND s.status != -1 "
	+ " WHERE c.id = " + courseId + " AND c.site_id = " + siteId + " AND c.status != -1 "
);

if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과목이 없습니다.");
	result.print();
	return;
}

String ss = info.s("study_sdate");
String se = info.s("study_edate");
String ssConv = !"".equals(ss) ? m.time("yyyy.MM.dd", ss) : "";
String seConv = !"".equals(se) ? m.time("yyyy.MM.dd", se) : "";
info.put("period_conv", (!"".equals(ssConv) && !"".equals(seConv)) ? (ssConv + " - " + seConv) : "");

String courseIdConv = !"".equals(info.s("course_cd")) ? info.s("course_cd") : (info.i("id") + "");
info.put("course_id_conv", courseIdConv);

info.put("course_file_url", !"".equals(info.s("course_file")) ? m.getUploadUrl(info.s("course_file")) : "");

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", info);
result.print();

%>

