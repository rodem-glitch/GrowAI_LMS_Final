<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 학사 과목의 성적(A/B/C/D/F)을 DB에 저장합니다.

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
f.addElement("grades_json", "", "hname:'성적 JSON'");

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
String gradesJson = f.get("grades_json");

DataSet items = new DataSet();
if(!"".equals(gradesJson)) {
	try {
		items = malgnsoft.util.Json.decode(gradesJson);
	} catch(Exception e) {
		result.put("rst_code", "1002");
		result.put("rst_message", "grades_json 파싱에 실패했습니다.");
		result.print();
		return;
	}
}

PolyCourseGradeDao grade = new PolyCourseGradeDao();
// 왜: Resin이 예전 클래스(기본 PK=id)로 로딩한 상태여도, 여기서 명시적으로 고정해 INSERT(id 자동추가) 오류를 막습니다.
grade.PK = "site_id,course_code,open_year,open_term,bunban_code,group_code,member_key";
grade.useSeq = "N";

// 왜: 화면에서 전달된 전체 목록을 기준으로 덮어쓰기하여 상태를 단순화합니다.
grade.delete(
	"site_id = " + siteId
	+ " AND course_code = '" + m.replace(courseCode, "'", "''") + "'"
	+ " AND open_year = '" + m.replace(openYear, "'", "''") + "'"
	+ " AND open_term = '" + m.replace(openTerm, "'", "''") + "'"
	+ " AND bunban_code = '" + m.replace(bunbanCode, "'", "''") + "'"
	+ " AND group_code = '" + m.replace(groupCode, "'", "''") + "'"
);

items.first();
while(items.next()) {
	String studentId = items.s("student_id");
	String gradeValue = items.s("grade");
	int score = items.i("score");

	if("".equals(studentId)) continue;

	grade.item("site_id", siteId);
	grade.item("course_code", courseCode);
	grade.item("open_year", openYear);
	grade.item("open_term", openTerm);
	grade.item("bunban_code", bunbanCode);
	grade.item("group_code", groupCode);
	grade.item("member_key", studentId);
	grade.item("grade", gradeValue);
	grade.item("score", score);
	grade.item("reg_date", m.time("yyyyMMddHHmmss"));
	grade.item("status", 1);

	if(!grade.insert()) {
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

