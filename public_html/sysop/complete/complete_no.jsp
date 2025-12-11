<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.reqInt("cuid");
if(id == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

DataSet info = courseUser.find("id = " + id, "complete_no");
if(!info.next()) { m.jsError("유효한 데이타가 없습니다."); return; }

//폼체크
f.addElement("complete_no", info.s("complete_no"), "hname:'회원소속', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	courseUser.item("complete_no", f.get("complete_no"));
	if(!courseUser.update("id = " + id)) { m.jsAlert("회원소속을 수정하는 중 오류가 발생했습니다."); return; }
	
	m.js("parent.document.getElementById('cno_" + id + "').innerHTML = '" + f.get("complete_no") + "'; parent.CloseLayer();");
	return;
}


//출력
p.setLayout("poplayer");
p.setBody("complete.complete_no");
p.setVar("p_title", "수료번호 수정");
p.setVar("form_script", f.getScript());
p.display();

%>