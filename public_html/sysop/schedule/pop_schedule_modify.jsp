<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(37, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//유효성검사
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ScheduleDao schedule = new ScheduleDao();
MCal mcal = new MCal();

DataSet info = schedule.find("id = " + id + " AND status = 1");
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

//폼체크
f.addElement("sch_type", info.s("sch_type"), "hname:'일정구분', required:'Y'");
f.addElement("sch_nm", info.s("sch_nm"), "hname:'일정명', required:'Y'");
f.addElement("start_date", m.time("yyyy-MM-dd", info.s("start_date")), "hname:'시작일', required:'Y'");
f.addElement("start_time_hour", info.s("start_time").substring(0, 2), "hname:'시작시간(시)', required:'Y'");
f.addElement("start_time_min", info.s("start_time").substring(2, 4), "hname:'시작시간(분)', required:'Y'");
f.addElement("end_date", m.time("yyyy-MM-dd", info.s("end_date")), "hname:'종료일', required:'Y'");
f.addElement("end_time_hour", info.s("end_time").substring(0, 2), "hname:'종료시간(시)', required:'Y'");
f.addElement("end_time_min", info.s("end_time").substring(2, 4), "hname:'종료시간(분)', required:'Y'");
f.addElement("content", null, "hname:'세부내용'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부', required:'Y'");

//수정
if(m.isPost() && f.validate()) {
	schedule.item("sch_type", f.get("sch_type"));
	schedule.item("sch_nm", f.get("sch_nm"));
	schedule.item("start_date", m.time("yyyyMMdd", f.get("start_date")));
	schedule.item("end_date", m.time("yyyyMMdd", f.get("end_date")));
	schedule.item("start_time", f.get("start_time_hour") + f.get("start_time_min") + "00");
	schedule.item("end_time", f.get("end_time_hour") + f.get("end_time_min") + "00");
	schedule.item("content", f.get("content"));
	schedule.item("display_yn", f.get("display_yn"));
	if(!schedule.update("id = " + id)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//이동
	m.js("parent.location.href = parent.location.href;");
	return;
}
//출력
p.setLayout("poplayer");
p.setBody("schedule.pop_schedule_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("modify", true);
p.setVar(info);

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes());
p.setLoop("types", schedule.query("SELECT DISTINCT sch_type FROM " + schedule.table + " WHERE site_id = " + siteId + " AND status != -1"));
p.display();

%>