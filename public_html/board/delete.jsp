<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { auth.loginForm(); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
CommentDao comment = new CommentDao();

//정보
DataSet info = post.find("id = ? AND site_id = " + siteId + " AND display_yn = 'Y' AND status = 1", new Object[] { id });
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//제한-작성자
if(userId != info.i("user_id") && !isBoardAdmin) { m.jsError(_message.get("alert.common.permission_delete")); return; }

//제한-답글여부
if(post.getReplyCount(info.i("thread"), info.s("depth"), info.i("id")) > 0) {
	m.jsError(_message.get("alert.post.delete_with_reply"));
	return;
}

//제한-댓글여부
if(!binfo.b("delete_yn") && 0 < comment.findCount("module = 'post' AND module_id = " + id + " AND status = 1")) {
	m.jsError(_message.get("alert.post.delete_with_comment"));
	return;
}

//삭제
post.item("status", -1);
if(!post.update("id = " + id)) { m.jsError(_message.get("alert.post.error_delete")); return; }

//첨부 파일
DataSet files = file.getFileList(id);
while(files.next()) {
	if(!"".equals(files.s("filename"))) m.delFileRoot(m.getUploadPath(files.s("filename")));
}

//삭제-첨부파일
file.item("status", -1);
if(!file.update("module = 'post' AND module_id = " + id)) { m.jsError(_message.get("alert.file.error_delete")); return; }

//이동
m.jsReplace("index.jsp?" + m.qs("id,page"));

%>