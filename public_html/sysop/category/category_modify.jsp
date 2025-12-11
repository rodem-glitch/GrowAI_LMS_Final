<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(13, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CategoryDao category = new CategoryDao();

String module = m.rs("md", "faq");
int id = m.ri("id");
if(id == 0) {
	DataSet tops = category.query(
		"SELECT a.*"
		+ " FROM " + category.table + " a "
		+ " WHERE a.site_id = " + siteinfo.i("id") + " a.module = '" + module + "' AND a.status = 1 "
		+ " ORDER BY a.sort ASC "
		, 1
	);
	if(tops.next()) {
		id = tops.i("id");
	} else {
		m.jsReplace("category_insert.jsp?" + m.qs());
		return;
	}
}

//정보
DataSet info = category.find("id = " + id);
if(!info.next()) { m.jsError("해당 정보는 없습니다."); return; }

//폼체크
f.addElement("category_nm", info.s("category_nm"), "hname:'카테고리명', required:'Y'");
f.addElement("sort", info.i("sort"), "hname:'순서', option:'number', required:'Y'");

//수정
if(m.isPost() && f.validate()) {
	category.item("category_nm", f.get("category_nm"));

	if(!category.update("id = " + id)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	if(f.getInt("sort") != info.i("sort")) category.sort(id, f.getInt("sort"), info.i("sort"));

	out.print("<script>parent.left.location.href='category_tree.jsp?md=" + module + "';</script>");
	m.jsReplace("category_modify.jsp?" + m.qs());
	return;
}

//모듈목록
DataSet modules = m.arr2loop(category.modules);
while(modules.next()) {
	modules.put("selected", modules.s("id").equals(module) ? "selected" : "");
}

int maxCnt = category.findCount("site_id = " + siteinfo.i("id") + " AND module = '" + module + "' AND status = 1");

DataSet sortList = new DataSet();
for(int i=0; i<maxCnt; i++) {
	sortList.addRow();
	sortList.put("idx", i+1);
}

//출력
p.setLayout("blank");
p.setBody("category.category_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("modify", true);

p.setLoop("modules", modules);
p.setLoop("sorts", sortList);
p.display();

%>