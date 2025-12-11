<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!Menu.accessible(72, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
ExamDao exam = new ExamDao();
QuestionDao question = new QuestionDao();
QuestionCategoryDao questionCategory = new QuestionCategoryDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();
CourseModuleDao courseModule = new CourseModuleDao();

//정보
DataSet info = exam.query(
	"SELECt a.*, g.category_nm category_nm, u.user_nm manager_name "
	+ " FROM " + exam.table + " a "
	+ " LEFT JOIN " + category.table + " g ON a.category_id = g.id "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 AND a.site_id = " + siteId + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }


//폼체크
f.addElement("category_id", info.s("category_id"), "hname:'카테고리명'");
f.addElement("category_nm", category.getTreeNames(info.i("category_id")), "hname:'카테고리'");
f.addElement("exam_nm", info.s("exam_nm"), "hname:'평가명', required:'Y'");
f.addElement("exam_time", info.i("exam_time"), "hname:'평가시간', option:'number', required:'Y'");
f.addElement("shuffle_yn", info.s("shuffle_yn"), "hname:'보기섞기'");
f.addElement("auto_complete_yn", info.s("auto_complete_yn"), "hname:'자동채점여부'");
//f.addElement("retake_yn", info.s("retake_yn"), "hname:'재응시여부', required:'Y'");
//f.addElement("permission_number", info.i("permission_number"), "hname:'재응시횟수', option:'number'");
if(!courseManagerBlock) f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
if(!courseManagerBlock) f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("status", info.i("status"), "hname:'상태', required:'Y'");

//배점
DataSet grades = m.arr2loop(question.grades);
while(grades.next()) {
	grades.put("mcnt_value", info.i("mcnt" + grades.i("id")));
	grades.put("tcnt_value", info.i("tcnt" + grades.i("id")));
	grades.put("assign_value", info.i("assign" + grades.i("id")));
}

//등록
if(m.isPost() && f.validate()) {

	exam.item("category_id", f.get("category_id"));
	exam.item("exam_nm", f.get("exam_nm"));
	exam.item("range_idx", m.join(",", f.getArr("cid")));
	exam.item("exam_time", f.getInt("exam_time"));
	exam.item("content", f.get("content"));
	exam.item("question_cnt", f.getInt("question_cnt"));
	exam.item("auto_complete_yn", f.get("auto_complete_yn", "N"));
	exam.item("shuffle_yn", f.get("shuffle_yn", "N"));
//	exam.item("retake_yn", f.get("retake_yn", "N"));
//	exam.item("permission_number", f.getInt("permission_number"));

	//배점
	grades.first();
	while(grades.next()) {
		exam.item("mcnt" + grades.i("id"), f.getInt("mcnt" + grades.i("id")));
		exam.item("tcnt" + grades.i("id"), f.getInt("tcnt" + grades.i("id")));
		exam.item("assign" + grades.i("id"), f.getInt("assign" + grades.i("id")));
	}
	if(!courseManagerBlock) exam.item("manager_id", f.get("manager_id"));
	exam.item("status", f.getInt("status"));
	if(!exam.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//수정
	if(!info.s("exam_nm").equals(f.get("exam_nm"))) {
		courseModule.item("module_nm", f.get("exam_nm"));
		if(!courseModule.update("site_id = " + siteId + " AND module = 'exam' AND module_id = " + id)) {
			m.jsAlert("기존 시험명을 수정하는 중 오류가 발생했습니다.");
			return;
		}
	}

	//이동
	m.jsReplace("exam_list.jsp?" + m.qs("id"), "parent");
	return;

}

//문제카테고리
DataSet rangeList = new DataSet();
if(!"".equals(info.s("range_idx"))) {
	String rangeIdx = "'" + m.join("','" , info.s("range_idx").split(",")) + "'";
	rangeList = questionCategory.find("id IN (" + rangeIdx + ")");
	questionCategory.setData(rangeList);
	while(rangeList.next()) {
		rangeList.put("cate_name", questionCategory.getTreeNames(rangeList.i("id")));
	}
}

//출력
p.setBody("exam.exam_insert" + ("F".equals(info.s("onoff_type")) ? "_off" : ""));
p.setVar("form_script", f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar("modify", true);
p.setVar(info);
p.setVar("temp_id", id);

p.setLoop("status_list", m.arr2loop(exam.statusList));
p.setLoop("grades", grades);
p.setLoop("range_list", rangeList);
p.setLoop("managers", user.getManagers(siteId));

p.setLoop("courses", courseModule.getCourses("exam", id));
p.setVar("course_cnt", courseModule.getCourseCount("exam", id));
p.setLoop("categories", category.getList(siteId));

p.display();

%>