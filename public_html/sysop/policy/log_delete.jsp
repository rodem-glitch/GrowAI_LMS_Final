<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(138, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
InfoLogDao infoLog = new InfoLogDao(siteId);

//정보
DataSet info = infoLog.find("id = " + id + " AND status != -1 AND site_id = " + siteId);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
if(-1 == infoLog.execute("UPDATE " + infoLog.table + " SET status = -1 WHERE id = " + id + " AND site_id = " + siteId)) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//이동
m.js("parent.location.href = parent.location.href;");

%>