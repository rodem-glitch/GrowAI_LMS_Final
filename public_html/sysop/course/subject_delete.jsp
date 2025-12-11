<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(79, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SubjectDao subject = new SubjectDao();
CourseDao course = new CourseDao();

//정보
DataSet info = subject.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한
if(0 < course.findCount("status != -1 AND subject_id = " + id + " AND site_id = " + siteId + "")) {
	m.jsError("해당 과정명을 개설과정에서 사용 중입니다. 삭제할 수 없습니다.");
	return;
}

//삭제
if(-1 == subject.execute("UPDATE " + subject.table + " SET status = -1 WHERE id = " + id + "")) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

//이동
m.jsReplace("subject_list.jsp?" + m.qs("id"));

%>