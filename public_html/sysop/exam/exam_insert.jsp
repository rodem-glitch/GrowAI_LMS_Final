<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!Menu.accessible(72, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String onoff = m.rs("onoff");
if("".equals(onoff)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ExamDao exam = new ExamDao();
QuestionDao question = new QuestionDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();

//난이도
DataSet grades = m.arr2loop(question.grades);
while(grades.next()) {
	grades.put("mcnt", grades.i("mcnt"));
	grades.put("tcnt", grades.i("tcnt"));
}


//폼체크
f.addElement("category_id", null, "hname:'카테고리명'");
f.addElement("exam_nm", null, "hname:'시험명', required:'Y'");
f.addElement("exam_time", 60, "hname:'시험시간', option:'number', required:'Y'");
f.addElement("shuffle_yn", "Y", "hname:'보기섞기'");
f.addElement("auto_complete_yn", "N", "hname:'자동채점여부'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int newId = exam.getSequence();

	exam.item("id", newId);
	exam.item("site_id", siteId);
	exam.item("category_id", f.get("category_id"));
	exam.item("onoff_type", onoff);
	exam.item("exam_nm", f.get("exam_nm"));
	exam.item("range_idx", m.join(",", f.getArr("cid")));
	exam.item("exam_time", f.getInt("exam_time"));
	exam.item("content", f.get("content"));
	exam.item("question_cnt", f.getInt("question_cnt"));
	exam.item("auto_complete_yn", f.get("auto_complete_yn", "N"));
	exam.item("shuffle_yn", f.get("shuffle_yn", "Y"));
	exam.item("retake_yn", "N");
	exam.item("permission_number", 0);
//	exam.item("retake_yn", f.get("retake_yn", "N"));
//	exam.item("permission_number", f.getInt("permission_number"));

	//난이도별 문제 갯수 및 점수 등록
	grades.first();
	while(grades.next()) {
		exam.item("mcnt" + grades.i("id"), f.getInt("mcnt" + grades.i("id")));
		exam.item("tcnt" + grades.i("id"), f.getInt("tcnt" + grades.i("id")));
		exam.item("assign" + grades.i("id"), f.getInt("assign" + grades.i("id")));
	}

	exam.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	exam.item("reg_date", m.time("yyyyMMddHHmmss"));
	exam.item("status", f.getInt("status"));
	if(!exam.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("exam_list.jsp?" + m.qs("id,onoff"), "parent");
	return;

}


//출력
p.setBody("exam.exam_insert" + ("F".equals(onoff) ? "_off" : ""));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,onoff"));
p.setVar("form_script", f.getScript());

p.setLoop("grades", grades);
p.setLoop("status_list", m.arr2loop(exam.statusList));
p.setVar("temp_id", m.getRandInt(-2000000, 1990000));
p.setLoop("categories", category.getList(siteId));
p.setLoop("managers", user.getManagers(siteId));

p.display();

%>