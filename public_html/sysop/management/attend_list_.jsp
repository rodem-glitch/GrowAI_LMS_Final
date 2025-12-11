<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseProgressDao courseProgress = new CourseProgressDao();
LessonDao lesson = new LessonDao();
TutorDao tutor = new TutorDao();

//목록
int userCnt = courseUser.findCount("status IN (1,3) AND course_id = " + courseId);
DataSet list = courseLesson.query(
	"SELECT a.*"
	+ ", tu.tutor_nm"
	+ ", le.lesson_nm"
	+ ", (SELECT COUNT(*) FROM " + courseProgress.table + " cp INNER JOIN " + courseUser.table + " cu ON cp.course_user_id = cu.id AND cu.status IN (1,3) WHERE cp.lesson_id = a.lesson_id AND cp.course_id = a.course_id AND cp.complete_yn = 'Y' AND cp.status = 1) complete_cnt"
	+ " FROM " + courseLesson.table + " a"
	+ " INNER JOIN " + lesson.table + " le ON a.lesson_id = le.id"
	+ " LEFT JOIN " + tutor.table + " tu ON a.tutor_id = tu.user_id"
	+ " WHERE a.status != -1 AND a.course_id = " + courseId
	+ " AND le.onoff_type = 'F' AND le.lesson_type = '11'"
	+ " ORDER BY a.chapter"
);
while(list.next()) {
	list.put("user_cnt_conv", m.nf(userCnt));
	list.put("complete_cnt_conv", m.nf(list.i("complete_cnt")));
	list.put("ratio", userCnt <= 0 ? "0" : m.nf(list.d("complete_cnt") / userCnt * 100, 1));

	list.put("start_date_conv", m.time("yyyy.MM.dd", list.s("start_date")));
	list.put("start_time_conv", m.time("HH:mm", "20000101" + list.s("start_time")));
	list.put("end_time_conv", m.time("HH:mm", "20000101" + list.s("end_time")));
}

//출력
p.setBody("management.attend_list");
p.setVar("p_title", ptitle);
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setLoop("list", list);
p.setVar("form_script", f.getScript());

p.display();

%>