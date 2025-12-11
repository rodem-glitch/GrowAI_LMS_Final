<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(27, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
PlaceDao place = new PlaceDao();
PlaceCategoryDao placeCategory = new PlaceCategoryDao();
CategoryDao category = new CategoryDao();
FileDao file = new FileDao();

//폼체크
f.addElement("place_nm", null, "hname:'교육장명', required:'Y'");
f.addElement("zipcode", null, "hname:'우편번호'");
f.addElement("new_addr", null, "hname:'주소'");
f.addElement("addr_dtl", null, "hname:'상세주소'");
f.addElement("contents", null, "hname:'설명', allowhtml:'Y'");
f.addElement("etc1", null, "hname:'기타1'");
f.addElement("etc2", null, "hname:'기타2'");
f.addElement("status", 1, "hname:'상태', required:'Y', option:'number'"); 

//등록
if(m.isPost() && f.validate()) {
	
	int newId = place.getSequence();

	place.item("id", newId);
	place.item("site_id", siteId);
	place.item("place_nm", f.get("place_nm"));
	place.item("zipcode", f.get("zipcode"));
	place.item("new_addr", f.get("new_addr"));
	place.item("addr_dtl", f.get("addr_dtl"));
	place.item("contents", f.get("contents"));
	place.item("etc1", f.get("etc1"));
	place.item("etc2", f.get("etc2"));
	place.item("reg_date", sysNow);
	place.item("status", f.getInt("status"));

	if(!place.insert()) {
		m.jsAlert("등록하는 중 오류가 발생했습니다.");
		return;
	}

	//카테고리
	if(null != f.getArr("category_id")) {
		placeCategory.item("place_id", newId);
		placeCategory.item("site_id", siteId);
		for(int i = 0; i < f.getArr("category_id").length; i++) {
			placeCategory.item("category_id", f.getArr("category_id")[i]);
			if(!placeCategory.insert()) { }
		}
	}

	//임시로 올려진 파일들의 게시물 아이디 지정
	file.updateTempFile(f.getInt("temp_id"), newId, "place");

	mSession.put("file_module", "");
	mSession.put("file_module_id", 0);
	mSession.save();

	m.jsReplace("place_list.jsp?MN=" + m.request("MN"), "parent");
	return;
}

int tempId = m.getRandInt(-2000000, 1990000);

mSession.put("file_module", "place");
mSession.put("file_module_id", tempId);
mSession.save();

//출력
p.setLayout("sysop");
p.setBody("content.place_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("place_id", tempId);

p.setLoop("display_yn", m.arr2loop(place.displayYn));
p.setLoop("status_list", m.arr2loop(place.statusList));
p.display();

%>