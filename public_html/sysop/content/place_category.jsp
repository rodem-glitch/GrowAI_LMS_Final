<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(6, userId, userKind))) { m.jsErrClose("접근권한이 없습니다."); return; }

//폼입력
String mode = m.rs("mode");
int id = m.ri("id");

//객체
CategoryDao category = new CategoryDao();

//코드체크
if("CHECK".equals(m.rs("mode"))) {
	String value = m.rs("v");
	if("".equals(value)) { return; }

	//중복여부
	if(0 < category.findCount("id = '" + value + "'")) out.print("<span class='bad'>Ｘ</span>");
	else out.print("<span class='good'>○</span>");
	return;
}

//최대값
int maxSort = category.findCount("site_id = " + siteId + " AND module_id = 0 AND module = 'place' AND status = 1");

//폼체크
f.addElement("sort", maxSort + 1, "hname:'순서', required:'Y'");
f.addElement("category_nm", null, "hname:'카테고리명', required:'Y'");

//모드별처리
if(m.isPost()) {

	//공통
	category.item("site_id", siteId);
	category.item("module_id", 0);
	category.item("module", "place");
//	category.item("sort", f.get("sort"));
	category.item("category_nm", f.get("category_nm"));

	//등록
	if("reg".equals(mode)) {
		if(!category.insert()) { m.jsAlert("등록하는 중 오류가 발생하였습니다."); return; }

		//순서정렬
		category.sort(category.getInsertId(), f.getInt("sort"), maxSort + 1);

	//수정
	} else if("mod".equals(mode)) {
		if("".equals(id)) { m.jsAlert("기본키는 반드시 지정해야 합니다. "); return; }

		//정보
		DataSet info = category.find("id = " + id);
		if(!info.next()){ m.jsAlert("해당 정보가 없습니다."); return; }

		if(!category.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생하였습니다."); return; }

		//순서정렬
		category.sort(id, f.getInt("sort"), info.i("sort"));

	//삭제
	} else if("del".equals(mode)) {
		if("".equals(id)) { m.jsAlert("기본키는 반드시 지정해야 합니다. "); return; }

		//정보
		DataSet info = category.find("id = '" + id + "'");
		if(!info.next()){ m.jsAlert("해당 정보가 없습니다."); return; }

		category.item("status", -1);
		if(!category.update("id = '" + id + "'")) { m.jsAlert("삭제하는 중 오류가 발생하였습니다."); return; }

		//순서정렬
		category.autoSort("place", 0, siteId);
	}

	m.jsReplace("place_category.jsp?" + m.qs(), "parent");
	return;
}


//순서
DataSet sortList = new DataSet();
for(int i = 0; i <= maxSort; i++) {
	sortList.addRow();
	sortList.put("sort", i+1);
}

//출력
p.setLayout("pop");
p.setBody("content.place_category");
p.setVar("p_title", "교육장카테고리관리");
p.setVar("form_script",  f.getScript());
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", category.find("site_id = " + siteId + " AND module_id = 0 AND module = 'place' AND status = 1", "*", "sort ASC"));
p.setLoop("sorts", sortList);
p.display();

%>