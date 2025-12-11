<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(92, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ManualDao manual = new ManualDao();

//정보
DataSet info = manual.find("id = " + id + " AND status != -1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//제한
if(0 < manual.findCount("parent_id = " + id + " AND status != -1")) {
	m.jsError("하위 매뉴얼이 있습니다. 삭제할 수 없습니다."); return;
}

//삭제
if(!manual.delete("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

//파일삭제
if(!"".equals(info.s("manual_file"))) { m.delFileRoot(m.getUploadPath(info.s("manual_file"))); }

//정렬
manual.autoSort(info.i("depth"), info.i("parent_id"));

//이동
out.print("<script>parent.left.location.reload();</script>");
m.jsReplace("manual_insert.jsp");

%>