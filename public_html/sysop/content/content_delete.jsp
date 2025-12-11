<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ContentDao content = new ContentDao();
LessonDao lesson = new LessonDao();

//정보
DataSet info = content.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
content.item("status", -1);
if(!content.update("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//차시
lesson.item("content_id", 0);
if(!lesson.update("content_id = " + id)) { }

m.jsReplace("content_list.jsp?" + m.qs("id"));

%>