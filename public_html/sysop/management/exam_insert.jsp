<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ExamDao exam = new ExamDao();
CourseModuleDao courseModule = new CourseModuleDao();
MCal mcal = new MCal();

//배점
int totalAssignScore = courseModule.getOneInt(
	"SELECT SUM(assign_score) FROM " + courseModule.table + " "
	+ " WHERE course_id = " + courseId + " AND module = 'exam' AND status = 1 "
);
int assignScore = cinfo.i("assign_exam") - totalAssignScore;
if(assignScore < 0) assignScore = 0;

//유효성 체크
f.addElement("id", null, "hname:'시험선택', required:'Y'");
if("R".equals(cinfo.s("course_type"))) {
	f.addElement("start_date", m.time("yyyy-MM-dd", cinfo.s("study_sdate")), "hname:'시작일', required:'Y'");
	f.addElement("start_date_hour", "14", "hname:'시작일(시)', required:'Y'");
	f.addElement("start_date_min", "00", "hname:'시작일(분)', required:'Y'");
	f.addElement("end_date", m.time("yyyy-MM-dd", cinfo.s("study_edate")), "hname:'종료일', required:'Y'");
	f.addElement("end_date_hour", "15", "hname:'마감일(시)', required:'Y'");
	f.addElement("end_date_min", "00", "hname:'마감일(분)', required:'Y'");
} else {
	f.addElement("chapter", 1, "hname:'차시', required:'Y'");
}
f.addElement("assign_score", assignScore, "hname:'배점', required:'Y'");
f.addElement("retry_yn", null, "hname:'재응시가능여부'");
f.addElement("retry_score", 0, "hname:'재응시기준점수'");
f.addElement("retry_cnt", 0, "hname:'재응시가능횟수'");
f.addElement("result_yn", "Y", "hname:'시험결과노출'");

//처리
if(m.isPost() && f.validate()) {

	//기본키
	int id = m.ri("id");
	if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//정보
	DataSet info = exam.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

	//제한
	if(0 < courseModule.findCount("course_id = " + courseId + " AND module = 'exam' AND module_id = " + id + " AND status != -1")) {
		m.jsAlert("해당 시험은 이미 배정되어 있습니다.");
		m.js("opener.location.href = opener.location.href; window.close();");
		return;
	}

	String applyType = "R".equals(cinfo.s("course_type")) ? "1" : "2";

	//추가
	courseModule.item("course_id", courseId);
	courseModule.item("site_id", siteId);
	courseModule.item("module", "exam");
	courseModule.item("module_id", id);
	courseModule.item("module_nm", info.s("exam_nm"));
	courseModule.item("parent_id", 0);
	courseModule.item("item_type", "R");
	courseModule.item("assign_score", f.getInt("assign_score"));
	courseModule.item("apply_type", applyType);
	courseModule.item("start_day", 0);
	courseModule.item("period", 0);
	courseModule.item("retry_yn", f.get("retry_yn", "N"));
	courseModule.item("retry_score", f.getInt("retry_score"));
	courseModule.item("retry_cnt", f.getInt("retry_cnt"));
	if("1".equals(applyType)) {
		courseModule.item("start_date", f.get("start_date").replace("-", "") + f.get("start_date_hour") + f.get("start_date_min") + "00");
		courseModule.item("end_date", f.get("end_date").replace("-", "") + f.get("end_date_hour") + f.get("end_date_min") + "00");
		courseModule.item("chapter", 0);
	} else {
		courseModule.item("start_date", "");
		courseModule.item("end_date", "");
		courseModule.item("chapter", f.getInt("chapter"));
	}
	courseModule.item("result_yn", f.get("result_yn", "N"));
	courseModule.item("status", 1);
	if(!courseModule.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("추가되었습니다.");
	m.js("opener.location.href = opener.location.href; window.close();");
	return;
}


//목록
DataSet list = exam.query(
	"SELECT a.id, a.exam_nm FROM " + exam.table + " a"
	+ " WHERE a.status = 1 AND a.site_id = " + siteId
	+ " AND NOT EXISTS ( "
	+ "   SELECT 1 FROM " + courseModule.table + " "
	+ "   WHERE course_id = " + courseId + " AND module = 'exam' AND module_id = a.id "
	+ " )" 
	+ (courseManagerBlock ? " AND manager_id IN (-99, " + userId + ")" : "")
	+ " ORDER BY a.id DESC"
);

//출력
p.setLayout("pop");
p.setBody("management.exam_insert");
p.setVar("p_title", "시험 추가");
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("is_regular", "R".equals(cinfo.s("course_type")));

p.setVar("course", cinfo);
p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes(10));
p.display();

%>