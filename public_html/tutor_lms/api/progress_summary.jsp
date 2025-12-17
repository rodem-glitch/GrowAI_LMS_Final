<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- "진도/출석" 탭은 차시(레슨)별로 전체 학습 현황(수강생 수/완료 수/평균 진도율)을 보여줘야 합니다.
//- 그래서 LM_COURSE_LESSON(차시 구성) + LM_COURSE_USER(수강생) + LM_COURSE_PROGRESS(진도)를 합쳐 요약 통계를 내려줍니다.

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
CourseUserDao courseUser = new CourseUserDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
LessonDao lesson = new LessonDao();

//권한: 교수자는 본인 과목(주강사)만, 관리자는 전체
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 진도를 조회할 권한이 없습니다.");
		result.print();
		return;
	}
}

DataSet list = courseLesson.query(
	" SELECT cl.chapter, cl.section_id, cl.lesson_id "
	+ " , cs.section_nm "
	+ " , l.lesson_nm, l.lesson_type, l.total_time "
	+ " , COUNT(cu.id) student_cnt "
	+ " , SUM(CASE WHEN cp.complete_yn = 'Y' THEN 1 ELSE 0 END) complete_cnt "
	+ " , IFNULL(AVG(IFNULL(cp.ratio, 0)), 0) avg_ratio "
	+ " , MAX(cp.last_date) last_date "
	+ " FROM " + courseLesson.table + " cl "
	+ " LEFT JOIN " + courseSection.table + " cs ON cs.id = cl.section_id AND cs.course_id = cl.course_id AND cs.status = 1 "
	+ " INNER JOIN " + lesson.table + " l ON l.id = cl.lesson_id AND l.status = 1 "
	//왜: 차시별 통계는 "현재 수강 중"인 사람 기준으로 계산합니다.
	+ " LEFT JOIN " + courseUser.table + " cu ON cu.course_id = cl.course_id AND cu.site_id = " + siteId + " AND cu.status NOT IN (-1, -4) "
	+ " LEFT JOIN " + courseProgress.table + " cp ON cp.course_user_id = cu.id AND cp.lesson_id = cl.lesson_id AND cp.site_id = " + siteId + " AND cp.status = 1 "
	+ " WHERE cl.course_id = " + courseId + " AND cl.site_id = " + siteId + " AND cl.status = 1 "
	+ " GROUP BY cl.chapter, cl.section_id, cl.lesson_id, cs.section_nm, l.lesson_nm, l.lesson_type, l.total_time "
	+ " ORDER BY cl.chapter ASC "
);

while(list.next()) {
	list.put("section_nm", !"".equals(list.s("section_nm")) ? list.s("section_nm") : "기본");
	list.put("lesson_nm", list.s("lesson_nm"));
	list.put("duration_conv", list.i("total_time") > 0 ? (list.i("total_time") + "분") : "-");

	int studentCnt = list.i("student_cnt");
	int completeCnt = list.i("complete_cnt");
	double completeRate = studentCnt > 0 ? Malgn.round(completeCnt * 100.0 / studentCnt, 1) : 0.0;
	list.put("complete_rate", completeRate);
	list.put("avg_ratio", Malgn.round(list.d("avg_ratio"), 1));

	String lastDate = list.s("last_date");
	list.put("last_date_conv", !"".equals(lastDate) ? m.time("yyyy.MM.dd HH:mm", lastDate) : "-");
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

