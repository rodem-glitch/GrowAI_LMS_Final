<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String code = m.rs("code", "notice");

//객체
BoardDao board = new BoardDao();
PostDao post = new PostDao();
FileDao file = new FileDao();
CategoryDao category = new CategoryDao();

//정보
DataSet binfo = board.find("code = '" + code + "' AND site_id = " + siteId + "");
if(!binfo.next()) { m.jsError(_message.get("alert.board.nodata")); return; }

String btype = binfo.s("board_type");
int bid = binfo.i("id");
int newHour = 24;
int listNum = 10;		//사용자-10
boolean isBoardAdmin = 0 != userId && "S".equals(userKind);
DataSet categories = binfo.b("category_yn") ? category.getList("board", bid, siteId) : new DataSet();	//카테고리

p.setVar(btype + "_type_block", true);

//로그인
if(userId == 0) { auth.loginForm(); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//정보
DataSet info = post.find("id = " + id + " AND site_id = " + siteId + " AND display_yn = 'Y' AND status = 1");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//제한-작성자
if(userId != info.i("user_id") && !isBoardAdmin) { m.jsError(_message.get("alert.common.permission_delete")); return; }

//제한-답글여부
if(post.getReplyCount(info.i("thread"), info.s("depth"), info.i("id")) > 0) {
	m.jsError(_message.get("alert.post.delete_with_reply"));
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
m.jsReplace("post_list.jsp?" + m.qs("id,page"));

%>