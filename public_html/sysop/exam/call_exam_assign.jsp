<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(72, userId, userKind)) { return; }

//폼입력
int eid = m.ri("eid");
String idx = m.rs("idx");

//객체
ExamDao exam = new ExamDao();
QuestionDao question = new QuestionDao();
LmCategoryDao category = new LmCategoryDao("course");

//정보
DataSet einfo = exam.find("id = " + eid + " AND status != -1");
if(!einfo.next()) einfo.next();

//문항 갯수
Hashtable<String, Object> map = new Hashtable<String, Object>();
DataSet questions = new DataSet();
if(!"".equals(idx)) {
	questions = question.query(
		"SELECT grade, COUNT(*) cnt "
		+ ", SUM(CASE WHEN question_type IN ('1','2') THEN 1 ELSE 0 END) mcnt "
		+ ", SUM(CASE WHEN question_type IN ('3','4') THEN 1 ELSE 0 END) tcnt "
		+ " FROM " + question.table + " "
		+ " WHERE status = 1 "
		+ " AND category_id IN (" + idx + ") AND site_id = " + siteId
		+ " GROUP BY grade "
	);
	while(questions.next()) {
		map.put("mcnt_" + questions.i("grade"), questions.i("mcnt"));
		map.put("tcnt_" + questions.i("grade"), questions.i("tcnt"));
	}
}

//목록
DataSet grades = m.arr2loop(question.grades);
while(grades.next()) {
	grades.put("mcnt", map.containsKey("mcnt_" + grades.i("id")) ? map.get("mcnt_" + grades.i("id")) : "0");
	grades.put("tcnt", map.containsKey("tcnt_" + grades.i("id")) ? map.get("tcnt_" + grades.i("id")) : "0");
	grades.put("mcnt_value", einfo.i("mcnt" + grades.i("id")));
	grades.put("tcnt_value", einfo.i("tcnt" + grades.i("id")));
	grades.put("assign_value", einfo.i("assign" + grades.i("id")));
}

//출력
p.setLayout(null);
p.setBody("exam.call_exam_assign");
p.setLoop("grades", grades);
//p.print(out, "../html/exam/call_exam_assign.html");
p.display();
%>