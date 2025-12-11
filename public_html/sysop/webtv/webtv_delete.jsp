<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!(Menu.accessible(123, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//객체
WebtvDao webtv = new WebtvDao();

//정보
DataSet info = webtv.find("id = ? AND status != -1 AND site_id = " + siteId, new Object[] {id});
if(!info.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

//삭제
webtv.item("status", "-1");
if(!webtv.update("id = " + id)) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//파일삭제
if(!"".equals(info.s("webtv_file"))) m.delFileRoot(m.getUploadPath(info.s("webtv_file")));

//이동
m.jsReplace("webtv_list.jsp?" + m.qs("id"));
return;

%>