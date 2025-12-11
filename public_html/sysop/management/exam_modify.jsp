<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int eid = m.ri("eid");
if(eid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
ExamDao exam = new ExamDao();
CourseModuleDao courseModule = new CourseModuleDao();
MCal mcal = new MCal();

//정보
DataSet info = courseModule.query(
	"SELECT a.*, b.exam_nm"
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " b ON a.module_id = b.id AND b.status != -1 AND b.site_id = " + siteId + " "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + courseId + " AND a.module_id = " + eid + " "
);
if(!info.next()) { m.jsErrClose("해당정보를 찾을 수 없습니다."); return; }

//유효성 체크
if("R".equals(cinfo.s("course_type"))) {
	f.addElement("start_date", m.time("yyyy-MM-dd", info.s("start_date")), "hname:'시작일', required:'Y'");
	f.addElement("start_date_hour", m.time("HH", info.s("start_date")), "hname:'시작일(시)', required:'Y'");
	f.addElement("start_date_min", m.time("mm", info.s("start_date")), "hname:'시작일(분)', required:'Y'");
	f.addElement("end_date", m.time("yyyy-MM-dd", info.s("end_date")), "hname:'종료일', required:'Y'");
	f.addElement("end_date_hour", m.time("HH", info.s("end_date")), "hname:'마감일(시)', required:'Y'");
	f.addElement("end_date_min", m.time("mm", info.s("end_date")), "hname:'마감일(분)', required:'Y'");
} else {
	f.addElement("chapter", info.i("chapter"), "hname:'차시', required:'Y'");
}
f.addElement("assign_score", info.i("assign_score"), "hname:'배점', required:'Y'");
f.addElement("retry_yn", info.s("retry_yn"), "hname:'재응시가능여부'");
f.addElement("retry_score", info.i("retry_score"), "hname:'재응시기준점수'");
f.addElement("retry_cnt", info.i("retry_cnt"), "hname:'재응시가능횟수'");
f.addElement("result_yn", info.s("result_yn"), "hname:'시험결과노출'");

//처리
if(m.isPost() && f.validate()) {

	String applyType = "R".equals(cinfo.s("course_type")) ? "1" : "2";

	courseModule.item("assign_score", f.getInt("assign_score"));
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
	if(!courseModule.update("module = 'exam' AND course_id = " + courseId + " AND module_id = " + eid + " ")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("수정되었습니다.");
	m.js("opener.location.href = opener.location.href; window.close();");
	return;
}

//출력
p.setLayout("pop");
p.setBody("management.exam_insert");
p.setVar("p_title", "시험 수정");
p.setVar("form_script", f.getScript());
p.setVar("is_regular", "R".equals(cinfo.s("course_type")));
p.setVar("modify", true);
p.setVar("course", cinfo);
p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes(10));
p.setVar(info);
p.display();

%>