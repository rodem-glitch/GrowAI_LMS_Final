<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(92, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
ManualDao manual = new ManualDao();
FileDao file = new FileDao();

//정보
DataSet info = manual.find("id = " + id + " AND status != -1");
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("description", null, "hname:'내용', allowhtml:'Y'");

//등록
if(m.isPost() && f.validate()) {

	manual.item("description", f.get("description"));
	if(!manual.update("id = " + id + "")) { m.jsErrClose("수정하는 중 오류가 발생했습니다."); return; }

	m.jsAlert("수정되었습니다.");
	m.js("parent.window.close();");
	return;
}

//출력
p.setLayout("pop");
p.setBody("manual.manual_content");
p.setVar("p_title", "매뉴얼 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.display();

%>