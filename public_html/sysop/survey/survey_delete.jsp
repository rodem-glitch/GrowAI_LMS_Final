<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(36, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SurveyDao survey = new SurveyDao();
CourseModuleDao courseModule = new CourseModuleDao();

//정보
DataSet info = survey.find("id = " + id + " AND status != -1 AND site_id = " + siteId + (courseManagerBlock ? " AND manager_id IN (-99, " + userId + ")" : ""));
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한-과정운영자
if(courseManagerBlock && -99 == info.i("manager_id")) {
	m.jsError("과정운영자는 공용 자료를 삭제할 수 없습니다."); return;
}

//제한-모듈
if(0 < courseModule.findCount("module = 'survey' AND module_id = " + id + "")) {
	m.jsError("해당 설문지는 개설된 과정에서 사용중입니다. 삭제할 수 없습니다.");
	return;
}


//삭제
survey.item("status", -1);
if(!survey.update("id = " + id + "")) {	m.jsError("삭제하는 중 오류가 발생했습니다.");	return; }

m.jsReplace("survey_list.jsp?" + m.qs("id"));

%>