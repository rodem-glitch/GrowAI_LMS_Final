<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- "담당과목" 화면의 년도 필터는 DB에 실제로 존재하는 년도만 보여줘야 사용자가 헷갈리지 않습니다.
//- 그래서 과정 목록을 전부 가져오지 않고도(성능), DISTINCT year 목록만 가볍게 조회합니다.

CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();

int tutorId = m.ri("tutor_id"); //관리자용 필터(선택)

//왜: 교수자는 본인 과목만, 관리자는 전체(또는 특정 교수자) 과목의 년도를 조회할 수 있어야 합니다.
String joinTutor = "";
if(!isAdmin) {
	joinTutor = " INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id AND ct.user_id = " + userId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ";
} else if(0 < tutorId) {
	joinTutor = " INNER JOIN " + courseTutor.table + " ct ON ct.course_id = c.id AND ct.user_id = " + tutorId + " AND ct.type = 'major' AND ct.site_id = " + siteId + " ";
}

DataSet list = course.query(
	" SELECT DISTINCT c.year "
	+ " FROM " + course.table + " c "
	+ joinTutor
	+ " WHERE c.site_id = " + siteId + " AND c.status != -1 AND c.onoff_type != 'P' AND c.year > 0 "
	+ " ORDER BY c.year DESC "
);

while(list.next()) {
	//왜: 프론트에서 바로 select 옵션으로 쓰기 쉽도록 문자열로 통일합니다.
	list.put("year", list.s("year"));
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

