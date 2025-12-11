<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(125, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String md = m.rs("md");
if("".equals(md)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
SitemapDao sitemap = new SitemapDao();
LmCategoryDao category = new LmCategoryDao(md);

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//변수
String table = "TB_WEBPAGE";
boolean categoryBlock = "LM_CATEGORY".equals(table);
ListManager lm = new ListManager();
DataSet list = new DataSet();

if(!categoryBlock) {
	//목록
	//lm.d(out);
	lm.setRequest(request);
	lm.setListNum(20);
	lm.setTable(table + " a");
	lm.setFields("a.id, a." + md + "_nm module_nm, a.reg_date");
	lm.addWhere("a.status = 1");
	lm.addWhere("a.site_id = " + siteId + "");
	if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
	else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("module_nm", f.get("s_keyword"), "LIKE");
	lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

	//포맷팅
	list = lm.getDataSet();
	while(list.next()) {
		//list.put("module_nm", list.s(md + "_nm"));
		list.put("module_nm_conv", m.cutString(list.s("module_nm"), 70));
		list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	}
} else if("etc".equals(md)) {
	//목록
	list = category.find("status = 1 AND module = '" + md + "'", "*", "parent_id ASC, sort ASC");
} else {
	//목록
	list = category.find("status = 1 AND module = '" + md + "' AND site_id = " + siteId + "", "*", "parent_id ASC, sort ASC");
}

//출력
p.setLayout("poplayer");
p.setBody("sitemap.module_select");
p.setVar("p_title", "모듈선택");

p.setVar("query", m.qs());
p.setVar("list_query", m.qs("md"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
if(!categoryBlock) p.setVar("list_total", lm.getTotalString());
if(!categoryBlock) p.setVar("pagebar", lm.getPaging());

p.setVar("category_block", categoryBlock);
p.display();

%>