<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(37, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ScheduleDao schedule = new ScheduleDao();

//정보
DataSet info = schedule.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
schedule.item("status", -1);
if(!schedule.update("id = " + id)) { m.jsAlert("삭제하는 중 오류가 발생했습니다."); return; }

//이동
m.js("parent.location.href = parent.location.href;");
return;

%>