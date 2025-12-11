<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(77, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
LibraryDao library = new LibraryDao();

//정보
DataSet info = library.find("id = " + id + " AND status != -1 AND site_id = " + siteId + (courseManagerBlock ? " AND manager_id IN (-99, " + userId + ")" : ""));
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한-과정운영자
if(courseManagerBlock && -99 == info.i("manager_id")) {
	m.jsError("과정운영자는 공용 자료를 삭제할 수 없습니다."); return;
}

//제한-모듈

//삭제
library.item("status", -1);
if(!library.update("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//삭제-파일
if(!"".equals(info.s("library_file"))) m.delFile(m.getUploadPath(info.s("library_file")));


//이동
m.jsReplace("library_list.jsp?" + m.qs("id"));

%>