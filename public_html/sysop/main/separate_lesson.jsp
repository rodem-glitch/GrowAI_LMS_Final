<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

/*
//객체
contentLessonDao_ contentLesson_ = new contentLessonDao_();
LessonDao lesson = new LessonDao();

//목록-중복된강의
DataSet list = contentLesson_.query(
	" SELECT a.content_id cid, l.* "
	+ " FROM " + contentLesson_.table + " a "
	+ " LEFT JOIN " + lesson.table + " l ON l.id = a.lesson_id "
	+ " WHERE a.lesson_id IN ( "
		+ " SELECT lesson_id FROM " + contentLesson_.table + " GROUP BY lesson_id HAVING COUNT(lesson_id) > 1"
	+ " ) "
	+ " ORDER BY l.site_id, a.lesson_id, a.content_id "
);
while(list.next()) {

	if(list.i("cid") == list.i("content_id")) { 
		m.p("[맵핑CID:" + list.s("cid") + "/레슨CID:" + list.s("content_id") + "/레슨ID:" + list.s("id") + "] 건너뛰기");
	} else {

		int newId = lesson.getSequence();

		lesson.item("id", newId);
		lesson.item("site_id", list.s("site_id"));
		lesson.item("content_id", list.s("cid"));
		lesson.item("onoff_type", list.s("onoff_type"));
		lesson.item("lesson_type", list.s("lesson_type"));
		lesson.item("lesson_nm", list.s("lesson_nm"));
		lesson.item("author", list.s("author"));
		lesson.item("start_url", list.s("start_url"));
		lesson.item("mobile_a", list.s("mobile_a"));
		lesson.item("mobile_i", list.s("mobile_i"));
		lesson.item("total_time", list.s("total_time"));
		lesson.item("complete_time", list.s("complete_time"));
		lesson.item("content_width", list.s("content_width"));
		lesson.item("content_height", list.s("content_height"));
		lesson.item("total_page", list.s("total_page"));
		lesson.item("lesson_hour", list.s("lesson_hour"));
		lesson.item("lesson_file", list.s("lesson_file"));
		lesson.item("description", list.s("description"));
		lesson.item("manager_id", list.s("manager_id"));
		lesson.item("use_yn", list.s("use_yn"));
		lesson.item("reg_date", list.s("reg_date"));
		lesson.item("status", list.s("status"));

		if(!lesson.insert()) {
			m.p("[맵핑CID:" + list.s("cid") + "/레슨CID:" + list.s("content_id") + "/레슨ID:" + list.s("id") + "] <span style='color:red;font-weight:bold;>등록실패</span>");
		} else {
			contentLesson_.item("lesson_id", newId);
			if(!contentLesson_.update("content_id = " + list.s("cid") + " AND lesson_id = " + list.s("id"))) {
				m.p("[맵핑CID:" + list.s("cid") + "/레슨CID:" + list.s("content_id") + "/레슨ID:" + list.s("id") + "] <span style='color:orange;font-weight:bold;>" + newId + " 수정실패</span>");
			}
		}
	}
}
*/

m.p("separate_lesson.jsp");

p.setLayout("blank");
p.setBody("");

p.display();

%>