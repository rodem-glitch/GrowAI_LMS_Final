<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(115, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
FormmailDao formmail = new FormmailDao();

//정보
DataSet info = formmail.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다.");	return; }

//삭제
formmail.item("status", -1);
if(!formmail.update("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

m.jsReplace("formmail_list.jsp?" + m.qs("id"));

%>