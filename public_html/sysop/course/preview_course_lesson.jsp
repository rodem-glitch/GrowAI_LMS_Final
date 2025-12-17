<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한(차시관리와 동일)
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid"); //과정
int lid = m.ri("lid"); //차시(부모 레슨)
if(cid == 0 || lid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseLessonVideoDao clv = new CourseLessonVideoDao();
LessonDao lesson = new LessonDao();

//왜: 다중영상 차시에서는 ‘부모 차시(메인)’가 실제로 재생되지 않을 수 있어,
//    운영자가 미리보기를 눌렀을 때 “첫 번째 서브영상”을 바로 확인할 수 있어야 합니다.
int targetLessonId = lid;

DataSet first = clv.query(
	"SELECT v.video_id "
	+ " FROM " + clv.table + " v "
	+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 AND l.site_id = " + siteId + " "
	+ " WHERE v.course_id = " + cid + " AND v.lesson_id = " + lid + " AND v.site_id = " + siteId + " AND v.status = 1 "
	+ " ORDER BY v.sort ASC "
	, 1
);
if(first.next() && 0 < first.i("video_id")) targetLessonId = first.i("video_id");

m.redirect("../content/preview_lesson.jsp?id=" + targetLessonId);

%>

