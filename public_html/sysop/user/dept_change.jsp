<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(19, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
if(!adminBlock) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String idx = m.rs("idx");
if("".equals(idx)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//변수
int maxSort = userDept.getOneInt(
	"SELECT MAX(sort) FROM " + userDept.table + " "
	+ " WHERE site_id = " + siteId + ""
);

//폼체크
f.addElement("dept_id", null, "hname:'회원소속', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	user.item("dept_id", f.get("dept_id"));
	if(!user.update("id IN (" + idx + ") AND site_id = " + siteId)) { m.jsAlert("회원소속을 수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("user_list.jsp?" + m.qs("idx"), "parent");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("user.dept_change");
p.setVar("p_title", "회원소속 변경");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("dept_list", userDept.getList(siteId));
p.display();

%>