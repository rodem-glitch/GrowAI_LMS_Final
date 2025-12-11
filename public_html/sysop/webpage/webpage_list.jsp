<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(127, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WebpageDao webpage = new WebpageDao();
SiteDao site = new SiteDao();

//폼체크
f.addElement("s_layout", null, null);
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(webpage.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.layout", f.get("s_layout"));
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.code, a.webpage_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("webpage_nm_conv", m.htt(list.s("webpage_nm")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), webpage.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "페이지관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[]{ "__ord=>고유값", "code=>코드", "layout=>레이아웃", "webpage_nm=>페이지명", "content=>내용", "reg_date_conv=>등록일", "status_conv=>상태"});
	ex.write();
	return;
}

//출력
p.setLayout(ch);
p.setBody("webpage.webpage_list");
p.setVar("p_title", "페이지관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,mode"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("layouts", webpage.getLayouts(tplRoot + "/html/layout"));
p.setLoop("status_list", m.arr2loop(webpage.statusList));
p.display();

%>