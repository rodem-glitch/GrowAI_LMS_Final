<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { out.print("0"); return; }

//객체
CourseUserDao courseUser = new CourseUserDao();
CourseDao course = new CourseDao();

//변수
String today = m.time("yyyyMMdd");

int courseCnt = courseUser.getOneInt(
	"SELECT COUNT(*) "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " WHERE a.user_id = " + userId + " AND a.status IN (0, 1, 3) "
	+ " AND a.close_yn = 'N' AND a.end_date >= '" + today + "' "
	+ " ORDER BY a.start_date ASC, a.id DESC "
);

out.print(courseCnt);

%>