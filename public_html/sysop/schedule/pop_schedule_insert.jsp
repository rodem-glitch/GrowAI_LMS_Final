<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(37, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ScheduleDao schedule = new ScheduleDao();
MCal mcal = new MCal();

String year = m.rs("year");
String month = m.rs("month", m.time("MM"));
String day = m.rs("day", m.time("dd"));
if(!"".equals(month)) {
	if(month.length() < 2) month = "0" + month;
}
if(!"".equals(day)) {
	if(day.length() < 2) day = "0" + day;
}

f.addElement("sch_type", null, "hname:'일정구분', required:'Y'");
f.addElement("sch_nm", null, "hname:'일정명', required:'Y'");
f.addElement("start_date", m.time("yyyy-MM-dd", year + month + day), "hname:'시작일', required:'Y'");
f.addElement("start_time_hour", "00", "hname:'시작시간(시)', required:'Y'");
f.addElement("start_time_min", "00", "hname:'시작시간(분)', required:'Y'");
f.addElement("end_date", m.time("yyyy-MM-dd", year + month + day), "hname:'종료일', required:'Y'");
f.addElement("end_time_hour", "23", "hname:'종료시간(시)', required:'Y'");
f.addElement("end_time_min", "59", "hname:'종료시간(분)', required:'Y'");
f.addElement("content", null, "hname:'세부내용'");
f.addElement("display_yn", "Y", "hname:'노출여부', required:'Y'");

if(m.isPost() && f.validate()) {

	schedule.item("site_id", siteId);
	schedule.item("sch_type", f.get("sch_type"));
	schedule.item("sch_nm", f.get("sch_nm"));
	schedule.item("start_date", m.time("yyyyMMdd", f.get("start_date")));
	schedule.item("end_date", m.time("yyyyMMdd", f.get("end_date")));
	schedule.item("start_time", f.get("start_time_hour") + f.get("start_time_min") + "00");
	schedule.item("end_time", f.get("end_time_hour") + f.get("end_time_min") + "00");
	schedule.item("content", f.get("content"));
	schedule.item("reg_date", m.time("yyyyMMddHHmmss"));
	schedule.item("display_yn", f.get("display_yn"));
	schedule.item("status", 1);
	if(!schedule.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

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

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes());
p.setLoop("types", schedule.query("SELECT DISTINCT sch_type FROM " + schedule.table + " WHERE site_id = " + siteId + " AND status != -1"));
p.display();

%>