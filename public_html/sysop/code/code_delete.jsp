<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!(Menu.accessible(3, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//유효성검사
int id = m.ri("id");
if(0 == id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CodeDao code = new CodeDao();

DataSet info = code.find("id = " + id + "");
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

if(code.findCount("parent_id = " + id + "") > 0) { m.jsError("하위코드가 존재합니다.\\n하위코드부터 삭제하셔야 합니다."); return; }

if(!code.delete("id = " + id + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

code.autoSort(info.i("depth"), info.i("parent_id"), siteinfo.i("id"));

out.print("<script>parent.left.location.href='code_tree.jsp';</script>");
m.jsReplace("code_insert.jsp");

%>