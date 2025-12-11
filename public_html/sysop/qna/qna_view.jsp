<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(93, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
ClFileDao clFile = new ClFileDao();
UserDao user = new UserDao();
CourseDao course = new CourseDao();

//정보
DataSet info = clPost.query(
	"SELECT a.*, b.board_nm, b.board_type, u.login_id "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " WHERE a.status != -1 AND a.id = " + id + " "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("hit_cnt_conv", m.nf(info.getInt("hit_cnt")));


//목록-파일
DataSet files = clFile.find("module = 'post' AND module_id = " + id + "");
while(files.next()) {
	files.put("file_ext", clFile.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(m.encode(files.s("filename"))));
	files.put("ext", clFile.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id")));
}
//출력
p.setBody("qna.qna_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("files", files);

p.setLoop("proc_status_list", m.arr2loop(clPost.procStatusList));
p.display();

%>