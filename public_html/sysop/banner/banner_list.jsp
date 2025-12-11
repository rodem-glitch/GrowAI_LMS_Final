<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(11, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
BannerDao banner = new BannerDao();

//폼체크
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록-유형
DataSet types = banner.query("SELECT DISTINCT banner_type FROM " + banner.table + " WHERE site_id = " + siteId + " AND status != -1");
if("json".equals(m.rs("mode"))) {
	response.setContentType("application/json;charset=utf-8");
	out.print(types.serialize());
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(banner.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteinfo.i("id"));
lm.addSearch("a.banner_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.banner_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("banner_nm_conv", m.cutString(list.s("banner_nm"), 50));
	//list.put("banner_type_conv", m.getItem(list.s("banner_type"), banner.types));
	list.put("target_conv", m.getItem(list.s("target"), banner.targets));
	list.put("status_conv", m.getItem(list.s("status"), banner.statusList));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "배너관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>고유값", "banner_type=>구분", "banner_nm=>배너명", "link=>링크", "target=>링크타겟", "width=>가로사이즈", "height=>세로사이즈", "sort=>순서", "reg_date=>등록일", "status=>상태" }, "배너관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("banner.banner_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
//p.setLoop("types", m.arr2loop(banner.types));
p.setLoop("types", types);
p.setLoop("targets", m.arr2loop(banner.targets));
p.display();

%>