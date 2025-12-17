<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 과정탐색/운영계획서 화면에서 특정 과정(프로그램)의 상세 정보(기본정보 + 운영계획서 JSON)를 읽어와야 합니다.

int id = m.ri("id");
if(0 == id) {
	result.put("rst_code", "1001");
	result.put("rst_message", "id(과정ID)가 필요합니다.");
	result.print();
	return;
}

SubjectDao subject = new SubjectDao();
SubjectPlanDao subjectPlan = new SubjectPlanDao();

//왜: 교수자는 본인 과정만, 관리자는 전체 과정을 조회할 수 있어야 합니다.
String whereOwner = !isAdmin ? (" AND user_id = " + userId + " ") : "";

DataSet info = null;
try {
	info = subject.query(
		" SELECT a.id, a.site_id, a.user_id, a.course_nm, a.start_date, a.end_date, a.reg_date, a.status "
		+ " , sp.plan_json "
		+ " FROM " + subject.table + " a "
		+ " LEFT JOIN " + subjectPlan.table + " sp ON sp.subject_id = a.id AND sp.site_id = " + siteId + " AND sp.status != -1 "
		+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1 "
		+ whereOwner
	);
} catch(Exception e) {
	//왜: 운영계획서 테이블(LM_SUBJECT_PLAN)이 아직 없을 수 있어도, 과정 상세(기본정보)는 보여야 합니다.
	info = subject.query(
		" SELECT a.id, a.site_id, a.user_id, a.course_nm, a.start_date, a.end_date, a.reg_date, a.status "
		+ " , '' plan_json "
		+ " FROM " + subject.table + " a "
		+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1 "
		+ whereOwner
	);
}

if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 과정이 없거나 조회 권한이 없습니다.");
	result.print();
	return;
}

info.put("course_nm_conv", m.cutString(info.s("course_nm"), 100));
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("start_date_conv", !"".equals(info.s("start_date")) ? m.time("yyyy.MM.dd", info.s("start_date")) : "");
info.put("end_date_conv", !"".equals(info.s("end_date")) ? m.time("yyyy.MM.dd", info.s("end_date")) : "");
info.put("training_period", (!"".equals(info.s("start_date")) && !"".equals(info.s("end_date")))
	? (m.time("yyyy.MM.dd", info.s("start_date")) + " - " + m.time("yyyy.MM.dd", info.s("end_date")))
	: ""
);

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", info);
result.print();

%>
