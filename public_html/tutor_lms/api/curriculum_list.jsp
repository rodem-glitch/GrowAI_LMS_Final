<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 강의목차 탭은 과목(LM_COURSE)의 차시(LM_COURSE_LESSON) + 섹션(LM_COURSE_SECTION) + 레슨(LM_LESSON)을 보여줘야 합니다.
//- 여기서는 화면에서 그룹핑하기 쉽도록 "섹션/레슨" 정보를 한 번에 내려줍니다.

int courseId = m.ri("course_id");
if(0 == courseId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseSectionDao courseSection = new CourseSectionDao();
LessonDao lesson = new LessonDao();

//권한: 교수자는 본인 과목(주강사)만, 관리자는 전체
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 강의목차를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet list = courseLesson.query(
	" SELECT cl.course_id, cl.section_id, cl.lesson_id, cl.chapter, cl.lesson_hour "
	+ " , cs.section_nm "
	+ " , l.lesson_nm, l.lesson_type, l.total_time, l.description "
	+ " FROM " + courseLesson.table + " cl "
	+ " LEFT JOIN " + courseSection.table + " cs ON cs.id = cl.section_id AND cs.course_id = cl.course_id AND cs.status = 1 "
	+ " INNER JOIN " + lesson.table + " l ON l.id = cl.lesson_id AND l.status = 1 "
	+ " WHERE cl.course_id = " + courseId + " AND cl.status = 1 "
	+ " ORDER BY cl.chapter ASC "
);

while(list.next()) {
	list.put("section_nm", !"".equals(list.s("section_nm")) ? list.s("section_nm") : "기본");
	list.put("lesson_nm", list.s("lesson_nm"));
	list.put("total_time_min", list.i("total_time"));
	list.put("duration_conv", list.i("total_time") > 0 ? (list.i("total_time") + "분") : "-");
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

