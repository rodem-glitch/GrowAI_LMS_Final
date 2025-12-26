<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 교수자가 만든 과정(프로그램)은 운영 중에도 이름/기간이 바뀔 수 있어서 수정 기능이 필요합니다.

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
SubjectPlanDao subjectPlan = new SubjectPlanDao();

//왜: 교수자는 본인 과정만, 관리자는 전체 과정을 수정할 수 있어야 합니다.
String whereOwner = !isAdmin ? (" AND user_id = " + userId + " ") : "";
DataSet info = subject.find("id = " + id + " AND site_id = " + siteId + " AND status != -1 " + whereOwner);
if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과정이 없거나 수정 권한이 없습니다.");
	result.print();
	return;
}

int ownerId = isAdmin ? info.i("user_id") : userId;

f.addElement("course_nm", info.s("course_nm"), "hname:'과정명', required:'Y'");
f.addElement("start_date", info.s("start_date"), "hname:'시작일'");
f.addElement("end_date", info.s("end_date"), "hname:'종료일'");
//왜: 화면의 상세 필드/반복 리스트는 JSON으로 한 번에 저장합니다. (없으면 기존 값 유지)
f.addElement("plan_json", "", "hname:'운영계획서 JSON'");

if(!f.validate()) {
	result.put("rst_code", "1000");
	result.put("rst_message", "필수값이 누락되었습니다.");
	result.print();
	return;
}

String courseNm = f.get("course_nm").trim();
String startDate = !"".equals(f.get("start_date")) ? m.time("yyyyMMdd", f.get("start_date")) : "";
String endDate = !"".equals(f.get("end_date")) ? m.time("yyyyMMdd", f.get("end_date")) : "";

// 기간 검증 (둘 다 입력된 경우에만)
if(!"".equals(startDate) && !"".equals(endDate) && 0 > m.diffDate("D", startDate, endDate)) {
	result.put("rst_code", "1100");
	result.put("rst_message", "종료일은 시작일보다 빠를 수 없습니다.");
	result.print();
	return;
}


//중복 방지(내 과정 내에서만)
DataSet dup = subject.query(
	" SELECT id FROM " + subject.table
	+ " WHERE site_id = " + siteId + " AND user_id = " + ownerId + " AND status != -1 AND course_nm = ? AND id != " + id,
	new Object[] { courseNm }
);
if(dup.next()) {
	result.put("rst_code", "1200");
	result.put("rst_message", "이미 같은 이름의 과정이 있습니다.");
	result.put("rst_data", dup.i("id"));
	result.print();
	return;
}

subject.item("course_nm", courseNm);
subject.item("start_date", startDate);
subject.item("end_date", endDate);

String whereUpdate = !isAdmin
	? ("id = " + id + " AND site_id = " + siteId + " AND user_id = " + userId + " AND status != -1")
	: ("id = " + id + " AND site_id = " + siteId + " AND status != -1");

if(!subject.update(whereUpdate)) {
	result.put("rst_code", "2000");
	result.put("rst_message", "저장 중 오류가 발생했습니다.");
	result.print();
	return;
}

//운영계획서/상세필드(JSON) 저장(빈 값이면 수정하지 않음)
try {
	String planJson = f.get("plan_json");
	if(!"".equals(planJson)) {
		if(0 < subjectPlan.findCount("subject_id = " + id + " AND site_id = " + siteId + " AND status != -1")) {
			subjectPlan.item("plan_json", planJson);
			subjectPlan.item("mod_date", m.time("yyyyMMddHHmmss"));
			subjectPlan.update("subject_id = " + id + " AND site_id = " + siteId + " AND status != -1");
		} else {
			subjectPlan.item("subject_id", id);
			subjectPlan.item("site_id", siteId);
			subjectPlan.item("plan_json", planJson);
			subjectPlan.item("reg_date", m.time("yyyyMMddHHmmss"));
			subjectPlan.item("status", 1);
			subjectPlan.insert();
		}
	}
} catch(Exception ignore) {
	//왜: 운영계획서 테이블(LM_SUBJECT_PLAN)이 아직 없는 환경에서도, 기본 정보 수정은 막히면 안 됩니다.
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", id);
result.print();

%>
