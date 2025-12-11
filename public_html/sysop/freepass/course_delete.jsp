<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(130, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
FreepassDao freepass = new FreepassDao(siteId);
FreepassCourseDao freepassCourse = new FreepassCourseDao(siteId);

//기본키
int fid = m.ri("fid");
if(fid == 0 || "".equals(m.rs("idx"))) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet finfo = freepass.find("id = '" + fid + "' AND site_id = " + siteinfo.i("id") + "");
if(!finfo.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼입력
String[] idx = m.rs("idx").split(",");

//삭제
if(-1 == freepassCourse.execute(
	"DELETE FROM " + freepassCourse.table + " "
	+ " WHERE freepass_id = " + fid + " "
	+ " AND course_id IN (" + m.join(",", idx) + ") "
)) {
	m.jsError("삭제하는 중 오류가 발생했습니다.");
	return;
}

//이동
m.jsReplace("../freepass/freepass_modify.jsp?id=" + fid);

%>