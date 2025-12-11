<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//CHECKED-2014.06.27

//접근권한
if(!Menu.accessible(16, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();

//정보
DataSet info = user.query(
	"SELECT a.*, t.tutor_file "
	+ " FROM " + user.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON t.user_id = a.id "
	+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.tutor_yn = 'Y' AND a.status != -1"
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한
if(0 < courseTutor.findCount("user_id = " + id + "")) {
	m.jsError("과정의 강사로 지정되어 있습니다. 삭제할 수 없습니다."); return;
}

//삭제
if(-1 == user.execute("UPDATE " + user.table + " SET status = -1 WHERE id = " + id + "")) {
	m.jsError("회원정보를 삭제하는 중에 오류가 발생했습니다.");
	return;
}

//삭제
tutor.item("tutor_file", "");
tutor.item("status", -1);
if(!tutor.update("user_id = " + id + "")) {
	//Rollback
	if(-1 == user.execute("UPDATE " + user.table + " SET status = " + info.s("status") + " WHERE id = " + id + "")) { }
	m.jsError("강사정보를 삭제하는 중에 오류가 발생했습니다.");
	return;
}

//파일삭제
if(!"".equals(info.s("tutor_file"))) m.delFileRoot(m.getUploadPath(info.s("tutor_file")));

//이동
m.jsReplace("tutor_list.jsp");

%>