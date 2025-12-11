<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("아이디는 반드시 지정해야 합니다. "); return; }

//정보
DataSet info = post.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 게시물이 존재하지 않습니다."); return; }

//제한-작성자
if(userId != info.i("user_id") && !isBoardAdmin) { m.jsError("관리자와 작성자만이 삭제할 수 있습니다."); return; }

//제한-답글여부
if(!"qna".equals(btype) && post.getReplyCount(info.i("thread"), info.s("depth"), info.i("id")) > 0) {
	m.jsError("답글이 있는 게시물은 삭제할 수 없습니다.");
	return;
}

//삭제
post.item("status", -1);
if(!post.update("id = " + id)) { m.jsError("게시물을 삭제하는 중 오류가 발생하였습니다."); return; }

//첨부 파일
DataSet files = file.getFileList(id);
while(files.next()) {
	if(!"".equals(files.s("filename"))) m.delFileRoot(m.getUploadPath(files.s("filename")));
}

//삭제-첨부파일
file.item("status", -1);
if(!file.update("module = 'post' AND module_id = " + id)) { m.jsError("첨부파일을 삭제하는 중 오류가 발생하였습니다."); return; }

//삭제-댓글
comment.item("status", -1);
if(!comment.update("module = 'post' AND module_id = " + id)) { m.jsError("댓글을 삭제하는 중 오류가 발생하였습니다."); return; }

//이동
m.jsReplace("index.jsp?" + m.qs("id,page"));

return;

%>