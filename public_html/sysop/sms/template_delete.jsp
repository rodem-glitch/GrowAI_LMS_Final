<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(133, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = smsTemplate.find("id = " + id + " AND site_id = " + siteId + " AND base_yn = 'N' AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
smsTemplate.item("status", "-1");
if(!smsTemplate.update("id = " + id)) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//이동
m.jsReplace("../sms/template_list.jsp");

%>