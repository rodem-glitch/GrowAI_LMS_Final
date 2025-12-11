<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
WebtvDao webtv = new WebtvDao();
WebtvLogDao webtvLog = new WebtvLogDao();
LmCategoryDao category = new LmCategoryDao("webtv");

//폼체트
f.addElement("s_start_date", null, null);
f.addElement("s_end_date", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(
	webtvLog.table + " a "
	+ " INNER JOIN " + webtv.table + " w ON a.webtv_id = w.id "
	+ " LEFT JOIN " + category.table + " c ON w.category_id = c.id "
);
lm.setFields("a.*, w.webtv_nm, c.category_nm");
lm.addWhere("a.user_id = " + uid + "");
if(!"".equals(f.get("s_start_date"))) lm.addWhere("a.reg_date >= '" + m.time("yyyyMMdd000000", f.get("s_start_date")) + "'");
if(!"".equals(f.get("s_end_date"))) lm.addWhere("a.reg_date <= '" + m.time("yyyyMMdd235959", f.get("s_end_date")) + "'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("c.category_nm, w.webtv_nm", f.get("s_keyword"), "LIKE");
lm.setOrderBy("a.reg_date DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
}

//출력
p.setLayout(ch);
p.setBody("crm.webtv_log_list");
p.setVar("p_title", "방송시청");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("tab_log", "current");
p.setVar("tab_sub_webtv", "current");
p.display();

%>