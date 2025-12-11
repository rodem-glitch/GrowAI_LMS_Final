<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(13, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

String module = m.rs("md", "faq");

//객체
CategoryDao category = new CategoryDao();

int maxCnt = category.findCount("site_id = " + siteId + " AND module = '" + module + "' AND status = 1");

//폼체크
f.addElement("category_nm", null, "hname:'카테고리명', required:'Y'");
f.addElement("sort", maxCnt + 1, "hname:'순서', option:'number', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	category.item("site_id", siteId);
	category.item("category_nm", f.get("category_nm"));
	category.item("module", module);
	category.item("module_id", 0);
	category.item("status", 1);

	if(!category.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	category.sort(category.getInsertId(), f.getInt("sort"), maxCnt + 1);

	out.print("<script>parent.left.location.href='category_tree.jsp?md=" + module + "';</script>");
	m.jsReplace("category_insert.jsp?" + m.qs());
	return;
}

//모듈목록
DataSet modules = m.arr2loop(category.modules);
while(modules.next()) {
	modules.put("selected", modules.s("id").equals(module) ? "selected" : "");
}

DataSet sortList = new DataSet();
for(int i=0; i<=maxCnt; i++) {
	sortList.addRow();
	sortList.put("idx", i+1);
}

//출력
p.setLayout("blank");
p.setBody("category.category_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setLoop("modules", modules);
p.setLoop("sorts", sortList);
p.display();

%>