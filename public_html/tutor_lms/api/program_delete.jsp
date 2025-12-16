<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과정(프로그램)을 삭제해도, 과목은 "소속 과정이 없을 수도 있음" 조건을 만족해야 하므로 과목의 소속을 먼저 해제합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int id = m.ri("id");
if(0 == id) {
	result.put("rst_code", "1001");
	result.put("rst_message", "id(과정ID)가 필요합니다.");
	result.print();
	return;
}

SubjectDao subject = new SubjectDao();
CourseDao course = new CourseDao();

//왜: 교수자는 본인 과정만, 관리자는 전체 과정을 삭제할 수 있어야 합니다.
String whereOwner = !isAdmin ? (" AND user_id = " + userId + " ") : "";
DataSet info = subject.find("id = " + id + " AND site_id = " + siteId + " AND status != -1 " + whereOwner);
if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과정이 없거나 삭제 권한이 없습니다.");
	result.print();
	return;
}

//연결된 과목 소속 해제(왜: 삭제 후에도 과목 화면이 깨지지 않게 하기 위함)
int detached = course.execute(
	" UPDATE " + course.table + " SET subject_id = 0 "
	+ " WHERE site_id = " + siteId + " AND subject_id = " + id + " AND status != -1 "
);

subject.item("status", -1);
String whereUpdate = !isAdmin
	? ("id = " + id + " AND site_id = " + siteId + " AND user_id = " + userId + " AND status != -1")
	: ("id = " + id + " AND site_id = " + siteId + " AND status != -1");

if(!subject.update(whereUpdate)) {
	result.put("rst_code", "2000");
	result.put("rst_message", "삭제 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", id);
result.put("rst_detached", detached);
result.print();

%>
