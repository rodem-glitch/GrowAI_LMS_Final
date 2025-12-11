<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int lid = m.ri("lid");
if(lid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); m.js("parent.CloseLayer();"); return; }

//객체
LessonDao lesson = new LessonDao();
CourseDao course = new CourseDao();
CourseLessonDao courseLesson = new CourseLessonDao();

//정보-강의
DataSet linfo = lesson.find("id = " + lid + " AND site_id = " + siteId + " AND status != -1");
if(!linfo.next()) { m.jsAlert("해당 정보가 없습니다."); m.js("parent.CloseLayer();"); return; }

//목록-차시
DataSet list = courseLesson.query(
	" SELECT a.*, c.course_nm "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " AND c.status != -1 "
	+ " WHERE a.lesson_id = " + lid + " AND a.status != -1 "
	+ " ORDER BY a.course_id ASC "
);
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 80));
}

//출력
p.setLayout("poplayer");
p.setBody("content.lesson_course");
p.setVar("p_title", "해당 강의를 사용 중인 과정");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("lid"));
p.setVar("query", m.qs());

p.setLoop("list", list);

p.display();

%>