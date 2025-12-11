<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init_classroom.jsp" %><%

//기본키
int id = m.ri("id");
String code = m.rs("code");
if(id == 0 && "".equals(code)) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
ClFileDao file = new ClFileDao();

//정보-게시판
DataSet binfo = board.find("course_id = " + courseId + " AND code = '" + code + "' AND status = 1");
if(!binfo.next()) { m.jsError(_message.get("alert.board.nodata")); return; }
String btype = binfo.s("board_type");
int bid = binfo.i("id");
binfo.put("type_" + btype, true);

//정보
DataSet info = post.find("id = " + id + " AND status = 1");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//제한
if(userId != info.i("user_id")) { m.jsError(_message.get("alert.common.permission_delete")); return; }

//삭제
if(-1 == post.execute("UPDATE " + post.table + " SET status = -1 WHERE id = " + id + "")) {
	m.jsError(_message.get("alert.common.error_delete")); return;
}

//목록-파일
DataSet files = file.find("module = 'post' AND module_id = " + id + " AND status = 1");
while(files.next()) {
	if(!"".equals(files.s("filename"))) m.delFileRoot(m.getUploadPath(files.s("filename")));
}

//삭제-파일
if(-1 == file.execute("UPDATE " + file.table + " SET status = -1 WHERE module = 'post' AND module_id = " + id + "")) {
	m.jsError(_message.get("alert.file.error_delete")); return;
}

m.jsReplace("cpost_list.jsp?cuid=" + cuid + "&code=" + code);

%>