<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(123, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
if(!adminBlock) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String idx = m.rs("idx");
if("".equals(idx)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
WebtvDao webtv = new WebtvDao();
LmCategoryDao category = new LmCategoryDao("webtv");

//폼체크
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	webtv.item("category_id", f.getInt("category_id"));

	if(!webtv.update("id IN (" + idx + ") AND site_id = " + siteId + " AND status != -1")) {
		m.jsAlert("카테고리를 수정하는 중 오류가 발생했습니다.");
		return;
	}

	//이동
	m.jsReplace("webtv_list.jsp?" + m.qs("idx"), "parent");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("webtv.category_change");
p.setVar("p_title", "카테고리수정");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("categories", category.getList(siteId));
p.display();

%>