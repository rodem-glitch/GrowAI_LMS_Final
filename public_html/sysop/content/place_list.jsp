<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(27, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
PlaceDao place = new PlaceDao();

//폼체크
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.request("mode")) ? 20000 : 20);
lm.setTable(place.table + " a");
lm.setFields("a.*");
lm.addWhere("a.site_id = " + siteId);
lm.addWhere("a.status = 1");
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.place_nm,a.zipcode,a.new_addr,a.addr_dtl,a.contents,a.etc1,a.etc2", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	/*
	list.put("id", m.numberFormat(list.getInt("id")));
	list.put("site_id", m.numberFormat(list.getInt("site_id")));
	list.put("place_nm", list.getString("place_nm"));
	list.put("zipcode", list.getString("zipcode"));
	list.put("new_addr", list.getString("new_addr"));
	list.put("addr_dtl", list.getString("addr_dtl"));
	list.put("contents", list.getString("contents"));
	list.put("etc1", list.getString("etc1"));
	list.put("etc2", list.getString("etc2"));
	list.put("reg_date", m.getTimeString("yyyy-MM-dd", list.getString("reg_date")));
	list.put("status", m.numberFormat(list.getInt("status")));
	list.put("board_nm_conv", m.cutString(list.s("board_nm"), 50));
	list.put("board_type_conv", m.getItem(list.s("board_type"), board.types));
	*/
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), place.statusList));
}

//엑셀
if("excel".equals(m.request("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "장소관리(" + m.getTimeString("yyyy-MM-dd") + ").xls"); 
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "place_nm=>교육장명", "zipcode=>우편번호", "new_addr=>주소", "addr_dtl=>상세주소", "contents=>교육장설명", "etc1=>기타1", "etc2=>기타2", "reg_date_conv=>등록일시", "status_conv=>상태" });
	ex.write();
	return;
}

//출력
p.setLayout("sysop");
p.setBody("content.place_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setLoop("display_yn", m.arr2loop(place.displayYn));
p.setLoop("status_list", m.arr2loop(place.statusList));
p.display();

%>