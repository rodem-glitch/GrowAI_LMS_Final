<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsErrClose(_message.get("alert.common.required_key")); return; }

//객체
ScheduleDao schedule = new ScheduleDao();

//정보
DataSet info = schedule.find("id = " + id + " AND site_id = " + siteId + " AND display_yn = 'Y' AND status = 1");
if(!info.next()) { m.jsAlert(_message.get("alert.common.nodata")); return; }
info.put("start_date_conv", m.time(_message.get("format.date.dot"), info.s("start_date")));
info.put("start_time_conv", info.s("start_time").substring(0, 2) + ":" + info.s("start_time").substring(2, 4));
info.put("end_date_conv", m.time(_message.get("format.date.dot"), info.s("end_date")));
info.put("end_time_conv", info.s("end_time").substring(0, 2) + ":" + info.s("end_time").substring(2, 4));
info.put("content_conv", m.nl2br(info.s("content")));

//출력
p.setLayout("blank");
p.setBody("schedule.schedule_view");
p.setVar(info);
p.display();

%>