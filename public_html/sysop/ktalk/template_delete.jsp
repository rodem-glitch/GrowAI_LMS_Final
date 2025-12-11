<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(137, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao();

//제한
if(!isUserMaster) { m.jsAlert("삭제할 수 없는 템플릿입니다."); return; }

//정보
DataSet info = ktalkTemplate.find("id = " + id + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
ktalkTemplate.item("status", "-1");
if(!ktalkTemplate.update("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//이동
m.jsReplace("../ktalk/template_list.jsp");

%>