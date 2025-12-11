<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(30, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LessonDao lesson = new LessonDao();
CourseLessonDao courseLesson = new CourseLessonDao();

DataSet info = lesson.find("id = " + m.ri("id"));
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

/*
int cUse = contentLesson.findCount("lesson_id = " + m.ri("id"));
if(cUse > 0) {
	m.jsError("사용중인 객체는 삭제하실 수 없습니다.\\n현재 " + cUse + "개의 콘텐츠과정이 사용 중입니다."); return;
}
*/

//제한
if(0 < courseLesson.findCount("lesson_id = " + m.ri("id") + " AND status = 1")) { m.jsError("과정에서 사용 중인 강의는 삭제할 수 없습니다."); return; }

//삭제
lesson.item("status", -1);
if(!lesson.update("id = " + m.ri("id"))) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

m.jsReplace("lesson_list.jsp?" + m.qs("id"));

%>