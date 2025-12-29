<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 학사 과목의 평가/수료 기준을 DB에서 읽어와 화면에 표시합니다.

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

PolyCourseSettingDao setting = new PolyCourseSettingDao();
DataSet info = setting.find(
	"site_id = " + siteId
	+ " AND course_code = ? AND open_year = ? AND open_term = ? AND bunban_code = ? AND group_code = ?"
	+ " AND status != -1"
	, new Object[] { courseCode, openYear, openTerm, bunbanCode, groupCode }
);

DataSet data = new DataSet();
data.addRow();
if(info.next()) {
	data.put("eval_json", info.s("eval_json"));
} else {
	data.put("eval_json", "");
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", data);
result.print();

%>

