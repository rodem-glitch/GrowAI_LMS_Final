<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
int cid = m.ri("cid");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();
CourseLessonDao courseLesson = new CourseLessonDao();
UserDao user = new UserDao();
FileDao file = new FileDao();

//제한
if(0 < courseLesson.findCount("lesson_id = " + id + " AND status = 1")) {
	m.jsError("과정에서 사용 중인 강의는 삭제할 수 없습니다.");
	return;
}

//정보-강의
DataSet info = lesson.find("id = " + id + " AND content_id = " + cid + " AND status != -1 AND site_id = " + siteId);
if(!info.next()) { m.jsError("해당 강의정보가 없습니다."); return; }

//삭제
lesson.item("status", -1);
if(!lesson.update("id = " + id + " AND content_id = " + cid + " AND status != -1 AND site_id = " + siteId)) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

//순서
if(cid > 0) lesson.autoSort(cid, siteId);

//삭제-교안파일
DataSet files = file.getFileList(id, "lesson");
while(files.next()) {
	if(file.delete(files.i("id"))) {
		if(!"".equals(files.s("filename"))) m.delFileRoot(m.getUploadPath(files.s("filename")));
	}
}

//이동
out.print("<script>try { parent.opener.location.reload(); } catch(e) { } parent.window.close();</script>");
return;

%>