<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { auth.loginForm(); return; }

//객체
ClPostDao post = new ClPostDao();

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//정보
DataSet info = post.find("id = ? AND site_id = " + siteId + " AND display_yn = 'Y' AND status = 1", new Object[] { id });
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//제한-작성자
if(userId != info.i("user_id")) { m.jsError(_message.get("alert.common.permission_delete")); return; }

//삭제
post.item("status", -1);
if(!post.update("id = " + id)) { m.jsError(_message.get("alert.post.error_delete")); return; }

//이동
m.jsReplace("review_list.jsp?" + m.qs("id"));

%>