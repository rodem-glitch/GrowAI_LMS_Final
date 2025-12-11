<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(13, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 지정해야 합니다."); return; }

//객체
CategoryDao category = new CategoryDao();

//정보
DataSet info = category.find("id = " + id + " AND status = 1");
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

category.item("status", -1);

if(!category.update("id = " + id + " AND status = 1")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

category.autoSort(info.s("module"), info.i("module_id"), siteinfo.i("id"));

out.print("<script>parent.left.location.href='category_tree.jsp?md=" + info.s("module") + "';</script>");
m.jsReplace("category_insert.jsp?" + m.qs("id"));

%>