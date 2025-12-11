<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//아이디
int eid = m.ri("eid");
String ranges = m.rs("ranges");

//객체
CourseDao course = new CourseDao();
ExamDao exam = new ExamDao();
CourseLessonDao cl = new CourseLessonDao();
QuestionDao question = new QuestionDao();
CourseCategoryDao category = new CourseCategoryDao();

//문항 갯수
DataSet gradeCnt = question.query(
	"SELECT grade, COUNT(*) cnt"
	+ ", SUM(CASE WHEN question_type IN (3, 4) THEN 1 ELSE 0 END) tcnt "
	+ " FROM " + question.table
	+ " WHERE status = 1 "
	+ " AND lesson_id IN (" + m.join(",", ranges.split(",")) + ") "
	+ " GROUP BY grade "
);

Hashtable<String, Object> quesCnt = new Hashtable<String, Object>();
while(gradeCnt.next()) {
	quesCnt.put("mcnt_" + gradeCnt.i("grade"), gradeCnt.i("cnt") - gradeCnt.i("tcnt"));
	quesCnt.put("tcnt_" + gradeCnt.i("grade"), gradeCnt.i("tcnt"));
}

DataSet einfo = new DataSet();
if(eid != 0) {
	einfo = exam.find("id = " + eid);
}
if(!einfo.next()) {
	einfo.addRow();
}

//난이도별 문제
DataSet gradeList = m.arr2loop(question.grades);

while(gradeList.next()) {
	gradeList.put("mcnt", quesCnt.containsKey("mcnt_" + gradeList.i("id")) ? quesCnt.get("mcnt_" + gradeList.i("id")) : "0");
	gradeList.put("tcnt", quesCnt.containsKey("tcnt_" + gradeList.i("id")) ? quesCnt.get("tcnt_" + gradeList.i("id")) : "0");
	gradeList.put("mcnt_value", einfo.i("mcnt" + gradeList.i("id")));
	gradeList.put("tcnt_value", einfo.i("tcnt" + gradeList.i("id")));
	gradeList.put("assign_value", einfo.i("assign" + gradeList.i("id")));
}

//페이지 출력
p.setLoop("grades", gradeList);
p.print(out, "/course/call_exam_assign.html");

%>