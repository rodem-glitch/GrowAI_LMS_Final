<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(27, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
PlaceDao place = new PlaceDao();
PlaceCategoryDao placeCategory = new PlaceCategoryDao();
CategoryDao category = new CategoryDao();

//기본키
int id = m.ri("id");
if(1 > id) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//정보
DataSet info = place.find("id = '" + id + "'");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("place_nm", info.s("place_nm"), "hname:'교육장명'");
f.addElement("zipcode", info.s("zipcode"), "hname:'우편번호'");
f.addElement("new_addr", info.s("new_addr"), "hname:'주소'");
f.addElement("addr_dtl", info.s("addr_dtl"), "hname:'상세주소'");
f.addElement("contents", null, "hname:'설명'");
f.addElement("etc1", info.s("etc1"), "hname:'기타1'");
f.addElement("etc2", info.s("etc2"), "hname:'기타2'");
f.addElement("status", info.i("status"), "hname:'상태', option:'number', required:'Y'"); 

//수정
if(m.isPost() && f.validate()) {
	place.item("place_nm", f.get("place_nm"));
	place.item("zipcode", f.get("zipcode"));
	place.item("new_addr", f.get("new_addr"));
	place.item("addr_dtl", f.get("addr_dtl"));
	place.item("contents", f.get("contents"));
	place.item("etc1", f.get("etc1"));
	place.item("etc2", f.get("etc2"));
	place.item("status", f.getInt("status"));

	if(!place.update("id = " + id + " AND site_id = " + siteId)) {
		m.jsAlert("수정하는 중 오류가 발생했습니다.");
		return;
	}

	//카테고리
	if(-1 != placeCategory.execute("DELETE FROM " + placeCategory.table + " WHERE place_id = " + id + "")) {
		if(null != f.getArr("category_id")) {
			placeCategory.item("place_id", id);
			placeCategory.item("site_id", siteId);
			for(int i = 0; i < f.getArr("category_id").length; i++) {
				placeCategory.item("category_id", f.getArr("category_id")[i]);
				if(!placeCategory.insert()) { }
			}
		}
	}

	//이동
	m.jsReplace("place_list.jsp?" + m.qs("id"), "parent");
	return;
}

info.put("reg_date_conv", m.time("yyyy-MM-dd HH:mm:ss", info.s("reg_date")));

//목록-카테고리
DataSet categories = placeCategory.query(
	"SELECT a.*, c.category_nm "
	+ " FROM " + placeCategory.table + " a "
	+ " INNER JOIN " + category.table + " c ON c.id = a.category_id "
	+ " WHERE a.place_id = " + id + " AND c.site_id = " + siteId + " AND c.status != -1 "
);

//출력
p.setLayout("sysop");
p.setBody("content.place_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("modify", true);
p.setVar("place_id", id);

p.setLoop("categories", categories);
p.setLoop("display_yn", m.arr2loop(place.displayYn));
p.setLoop("status_list", m.arr2loop(place.statusList));
p.display();

%>