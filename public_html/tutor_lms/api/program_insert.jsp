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
SubjectPlanDao subjectPlan = new SubjectPlanDao();

//왜: 교수자는 본인 과정만 생성, 관리자는 필요 시 특정 교수자(tutor_id) 소유로 생성할 수 있어야 합니다.
int ownerId = userId;
int tutorId = m.ri("tutor_id"); //관리자용(선택)
if(isAdmin && 0 < tutorId) ownerId = tutorId;

//입력값(필수 최소)
f.addElement("course_nm", null, "hname:'과정명', required:'Y'");
f.addElement("start_date", null, "hname:'시작일', required:'Y'");
f.addElement("end_date", null, "hname:'종료일', required:'Y'");
//왜: 화면의 상세 필드/반복 리스트는 JSON으로 한 번에 저장합니다. (없으면 빈값 허용)
f.addElement("plan_json", "", "hname:'운영계획서 JSON'");

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

//운영계획서/상세필드(JSON) 저장(없어도 과정 생성은 가능하지만, 있으면 같이 저장)
try {
	String planJson = f.get("plan_json");
	if(!"".equals(planJson)) {
		//왜: 같은 SUBJECT_ID에 대해 재시도(중복)될 수 있으므로, 있으면 update / 없으면 insert로 처리합니다.
		if(0 < subjectPlan.findCount("subject_id = " + newId + " AND site_id = " + siteId + " AND status != -1")) {
			subjectPlan.item("plan_json", planJson);
			subjectPlan.item("mod_date", m.time("yyyyMMddHHmmss"));
			subjectPlan.update("subject_id = " + newId + " AND site_id = " + siteId + " AND status != -1");
		} else {
			subjectPlan.item("subject_id", newId);
			subjectPlan.item("site_id", siteId);
			subjectPlan.item("plan_json", planJson);
			subjectPlan.item("reg_date", m.time("yyyyMMddHHmmss"));
			subjectPlan.item("status", 1);
			subjectPlan.insert();
		}
	}
} catch(Exception ignore) {
	//왜: 운영계획서 보조테이블(LM_SUBJECT_PLAN)이 아직 없을 수 있어도, 과정 생성 자체는 성공해야 합니다.
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", newId);
result.print();

%>
