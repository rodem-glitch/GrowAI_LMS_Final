<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int lid = m.ri("lid");

//객체
CourseLessonDao courseLesson = new CourseLessonDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

//목록
DataSet info = courseLesson.query(
    "SELECT a.* "
    + ", l.onoff_type, l.lesson_nm, l.start_url, l.mobile_a, l.mobile_i, l.short_url, l.content_width, l.content_height, l.lesson_type, l.total_time, l.complete_time, l.description, l.status lesson_status, l.chat_yn, l.ai_chat_yn "
    + " FROM " + courseLesson.table + " a "
    + " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
    + " WHERE a.status = 1 "
    + " AND a.course_id = " + courseId
    + " AND a.lesson_id = " + lid
);
if(!info.next()) { m.jsErrClose(_message.get("alert.course_lesson.nodata")); return; }

String shortUrl = kollus.getPlayUrl(info.s("short_url"), "" + siteId + "_" + loginId, true, 0);
if("https".equals(request.getScheme())) shortUrl = shortUrl.replace("http://", "https://");
info.put("short_url", shortUrl);
info.put("short_url_conv", shortUrl);

//출력
p.setLayout(null);
p.setBody("classroom.viewer_short");

p.setVar(info);

p.display();

%>