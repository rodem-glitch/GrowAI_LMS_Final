<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(914, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = certificateTemplate.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
certificateTemplate.item("status", "-1");
if(!certificateTemplate.update("id = " + id)) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//이동
m.jsReplace("../certificate/template_list.jsp");

%>