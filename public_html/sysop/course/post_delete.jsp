<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(93, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
int bid = m.ri("bid");
String code = m.rs("code");
if(id == 0 || bid == 0 || "".equals(code)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
ClFileDao file = new ClFileDao();
CourseDao course = new CourseDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//정보-게시판
DataSet binfo = board.find("id = " + bid + " AND status = 1");
/*
DataSet binfo = board.query(
	" SELECT a.* "
	+ " FROM " + board.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " AND c.status != -1 "
		+ ("C".equals(userKind) ? " AND a.course_id IN (" + manageCourses + ") " : "")
	+ " WHERE a.id = " + bid
);
*/
if(!binfo.next()) { m.jsError("해당 게시판 정보가 없습니다."); return; }
String btype = binfo.s("board_type");

//정보
DataSet info = post.query(
	" SELECT a.* "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.id = " + id + " AND a.status != -1 "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
post.item("status", -1);
if(!post.update("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//파일삭제
DataSet files = file.find("module = 'post' AND module_id = " + id + "");
while(files.next()) {
	if("".equals(files.s("filename"))) m.delFile(m.getUploadPath(files.s("filename")));
}

//삭제-첨부파일
file.item("status", -1);
if(!file.update("module = 'post' AND module_id = " + id)) { m.jsError("첨부파일을 삭제하는 중 오류가 발생하였습니다."); return; }

m.jsReplace("post_list.jsp?" + m.qs("id, bid, page"));

%>