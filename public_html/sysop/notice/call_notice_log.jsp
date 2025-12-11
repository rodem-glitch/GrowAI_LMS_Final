<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
String type = m.rs("type");
if(0 == id || "".equals(type)) return;

//객체
NoticeLogDao noticeLog = new NoticeLogDao(siteId);

//등록
if(0 < userId) noticeLog.log(userId, id, type);
return;

%>