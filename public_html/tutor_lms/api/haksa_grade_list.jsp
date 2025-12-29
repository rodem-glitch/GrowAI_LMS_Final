<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 학사 과목의 성적(A/B/C/D/F)을 DB에서 읽어옵니다.

String courseCode = m.rs("course_code");
String openYear = m.rs("open_year");
String openTerm = m.rs("open_term");
String bunbanCode = m.rs("bunban_code");
String groupCode = m.rs("group_code");

if("".equals(courseCode) || "".equals(openYear) || "".equals(openTerm) || "".equals(bunbanCode) || "".equals(groupCode)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "학사 과목 키(course_code/open_year/open_term/bunban_code/group_code)가 필요합니다.");
	result.print();
	return;
}

PolyCourseGradeDao grade = new PolyCourseGradeDao();

ArrayList<Object> params = new ArrayList<Object>();
params.add(siteId);
params.add(courseCode);
params.add(openYear);
params.add(openTerm);
params.add(bunbanCode);
params.add(groupCode);

DataSet list = grade.query(
	" SELECT member_key student_id, grade, score "
	+ " FROM " + grade.table
	+ " WHERE site_id = ? AND course_code = ? AND open_year = ? AND open_term = ? "
	+ " AND bunban_code = ? AND group_code = ? AND status != -1 "
	+ " ORDER BY member_key ASC "
	, params.toArray()
);

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>
