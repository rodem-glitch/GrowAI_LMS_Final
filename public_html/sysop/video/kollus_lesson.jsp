<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String key = m.rs("key");
if("".equals(key)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); m.js("parent.CloseLayer();"); return; }

//객체
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();
CourseDao course = new CourseDao();
CourseLessonDao courseLesson = new CourseLessonDao();

//목록-강의
//lesson.d(out);
DataSet list = lesson.query(
	" SELECT a.*, c.content_nm "
	+ " FROM " + lesson.table + " a "
	+ " LEFT JOIN " + content.table + " c ON a.content_id = c.id "
	+ " WHERE a.lesson_type = '05' AND (a.start_url = '" + key + "' OR a.mobile_a = '" + key + "' OR a.mobile_i = '" + key + "') "
	+ " AND a.site_id = " + siteId + " AND a.status != -1"
);
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("total_time_conv", m.nf(list.i("total_time")));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 60));
	if(1 > list.i("content_id")) list.put("content_nm_conv", "[미지정]");
	else list.put("content_nm_conv", m.cutString(list.s("content_nm"), 20));
}

//출력
p.setLayout("poplayer");
p.setBody("video.kollus_lesson");
p.setVar("p_title", "해당 영상을 사용 중인 강의");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("lid"));
p.setVar("query", m.qs());

p.setLoop("list", list);

p.display();

%>