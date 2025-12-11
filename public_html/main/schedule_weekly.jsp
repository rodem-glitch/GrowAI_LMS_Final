<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
int strlen = m.ri("strlen") > 0 ? m.ri("strlen") : 24;

//객체
ScheduleDao schedule = new ScheduleDao();
MCal mcal = new MCal();

//변수
String today = m.time("yyyyMMdd");
String weekStart = m.time("yyyyMMdd", mcal.getWeekFirstDate(today));
String weekEnd = m.time("yyyyMMdd", mcal.getWeekLastDate(today));
boolean isScheduled = false;

//정보
DataSet list = schedule.find("('" + today + "' BETWEEN '" + weekStart + "' AND end_date) AND start_date <= '" + weekEnd + "' AND site_id = " + siteId + " AND display_yn = 'Y' AND status = 1", "*", "start_date ASC, id DESC");
while(list.next()) {
	isScheduled = true;
	list.put("sch_nm_conv", m.cutString(list.s("sch_nm"), strlen));
	list.put("start_date_conv", m.time(_message.get("format.date.dot"), list.s("start_date")));
	list.put("start_time_conv", list.s("start_time").substring(0, 2) + ":" + list.s("start_time").substring(2, 4));
	list.put("end_date_conv", m.time(_message.get("format.date.dot"), list.s("end_date")));
	list.put("end_time_conv", list.s("end_time").substring(0, 2) + ":" + list.s("end_time").substring(2, 4));
	list.put("content_conv", m.nl2br(list.s("content")));
}

//출력
p.setLayout(null);
p.setBody("main.schedule_weekly");

p.setVar(list);
p.setLoop("list", list);

p.setVar("single_block", list.size() == 1);
p.setVar("schedule_cnt", list.size());
p.setVar("is_scheduled", isScheduled);
p.display();

%>