<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 교수자가 "단기 과정(프로그램)"을 직접 개설하면, 그 안에 여러 과목을 묶어 관리할 수 있습니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

SubjectDao subject = new SubjectDao();

//왜: 교수자는 본인 과정만 생성, 관리자는 필요 시 특정 교수자(tutor_id) 소유로 생성할 수 있어야 합니다.
int ownerId = userId;
int tutorId = m.ri("tutor_id"); //관리자용(선택)
if(isAdmin && 0 < tutorId) ownerId = tutorId;

//입력값(필수 최소)
f.addElement("course_nm", null, "hname:'과정명', required:'Y'");
f.addElement("start_date", null, "hname:'시작일', required:'Y'");
f.addElement("end_date", null, "hname:'종료일', required:'Y'");

if(!f.validate()) {
	result.put("rst_code", "1000");
	result.put("rst_message", "필수값이 누락되었습니다.");
	result.print();
	return;
}

String courseNm = f.get("course_nm").trim();
String startDate = m.time("yyyyMMdd", f.get("start_date"));
String endDate = m.time("yyyyMMdd", f.get("end_date"));

//기간 검증(왜: 시작/종료가 뒤집히면 화면/조회가 모두 꼬입니다)
if(0 > m.diffDate("D", startDate, endDate)) {
	result.put("rst_code", "1100");
	result.put("rst_message", "종료일은 시작일보다 빠를 수 없습니다.");
	result.print();
	return;
}

//중복 방지(같은 교수자/사이트에서 같은 과정명은 1개만)
DataSet dup = subject.query(
	" SELECT id FROM " + subject.table
	+ " WHERE site_id = " + siteId + " AND user_id = " + ownerId + " AND status != -1 AND course_nm = ? ",
	new Object[] { courseNm }
);
if(dup.next()) {
	result.put("rst_code", "1200");
	result.put("rst_message", "이미 같은 이름의 과정이 있습니다.");
	result.put("rst_data", dup.i("id"));
	result.print();
	return;
}

int newId = subject.getSequence();
subject.item("id", newId);
subject.item("site_id", siteId);
subject.item("user_id", ownerId);
subject.item("course_nm", courseNm);
subject.item("start_date", startDate);
subject.item("end_date", endDate);
subject.item("reg_date", m.time("yyyyMMddHHmmss"));
subject.item("status", 1);

if(!subject.insert()) {
	result.put("rst_code", "2000");
	result.put("rst_message", "저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", newId);
result.print();

%>
