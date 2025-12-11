<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(71, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//폼입력
String mode = !"".equals(m.rs("mode")) ? m.rs("mode") : "category";
String cid = m.rs("cid");

//객체
QuestionCategoryDao category = new QuestionCategoryDao();

//목록
DataSet list = category.find("status = 1 AND site_id = " + siteId + (courseManagerBlock ? " AND manager_id IN (-99, " + userId + ")" : ""), "*", "parent_id ASC, sort ASC");

//출력
p.setLayout("blank");
p.setBody("question.category_tree");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.setVar(mode + "_block", true);
p.setVar("cid", cid);
p.display();

%>