<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 학사 과목 강의목차(주차/차시/콘텐츠)를 DB에 저장합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

f.addElement("course_code", null, "hname:'강좌코드', required:'Y'");
f.addElement("open_year", null, "hname:'연도', required:'Y'");
f.addElement("open_term", null, "hname:'학기', required:'Y'");
f.addElement("bunban_code", null, "hname:'분반코드', required:'Y'");
f.addElement("group_code", null, "hname:'학부/대학원 구분', required:'Y'");
f.addElement("curriculum_json", "", "hname:'강의목차 JSON'");

if(!f.validate()) {
	result.put("rst_code", "1000");
	result.put("rst_message", "필수값이 누락되었습니다.");
	result.print();
	return;
}

String courseCode = f.get("course_code");
String openYear = f.get("open_year");
String openTerm = f.get("open_term");
String bunbanCode = f.get("bunban_code");
String groupCode = f.get("group_code");
String curriculumJson = f.get("curriculum_json");

PolyCourseSettingDao setting = new PolyCourseSettingDao();
// 왜: Resin이 예전 클래스(기본 PK=id)로 로딩한 상태여도, 여기서 명시적으로 고정해 INSERT(id 자동추가) 오류를 막습니다.
setting.PK = "site_id,course_code,open_year,open_term,bunban_code,group_code";
setting.useSeq = "N";

int count = setting.findCount(
	"site_id = " + siteId
	+ " AND course_code = ? AND open_year = ? AND open_term = ? AND bunban_code = ? AND group_code = ?"
	+ " AND status != -1"
	, new Object[] { courseCode, openYear, openTerm, bunbanCode, groupCode }
);

setting.item("curriculum_json", curriculumJson);
setting.item("mod_date", m.time("yyyyMMddHHmmss"));

if(count > 0) {
	String safeCourseCode = m.replace(courseCode, "'", "''");
	String safeOpenYear = m.replace(openYear, "'", "''");
	String safeOpenTerm = m.replace(openTerm, "'", "''");
	String safeBunbanCode = m.replace(bunbanCode, "'", "''");
	String safeGroupCode = m.replace(groupCode, "'", "''");

	if(!setting.update(
		"site_id = " + siteId
		+ " AND course_code = '" + safeCourseCode + "'"
		+ " AND open_year = '" + safeOpenYear + "'"
		+ " AND open_term = '" + safeOpenTerm + "'"
		+ " AND bunban_code = '" + safeBunbanCode + "'"
		+ " AND group_code = '" + safeGroupCode + "'"
		+ " AND status != -1"
	)) {
		result.put("rst_code", "2000");
		result.put("rst_message", "저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
} else {
	setting.item("site_id", siteId);
	setting.item("course_code", courseCode);
	setting.item("open_year", openYear);
	setting.item("open_term", openTerm);
	setting.item("bunban_code", bunbanCode);
	setting.item("group_code", groupCode);
	setting.item("reg_date", m.time("yyyyMMddHHmmss"));
	setting.item("status", 1);

	if(!setting.insert()) {
		result.put("rst_code", "2000");
		result.put("rst_message", "저장 중 오류가 발생했습니다.");
		result.print();
		return;
	}
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.print();

%>

