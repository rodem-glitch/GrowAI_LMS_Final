<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(13, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

String module = m.rs("md", "faq");

//객체
CategoryDao category = new CategoryDao();

//목록
DataSet list = category.find("site_id = " + siteId + " AND module = '" + module + "' AND status = 1", "*", "sort ASC");

//출력
p.setLayout("blank");
p.setBody("category.category_tree");
p.setVar("p_title", module.toUpperCase());
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("md", module);
p.setLoop("list", list);

p.display();

%>