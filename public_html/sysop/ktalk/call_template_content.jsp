<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { return; }

//객체
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao();

//정보
DataSet info = ktalkTemplate.query(
	" SELECT a.* "
	+ " FROM " + ktalkTemplate.table + " a "
	+ " WHERE a.id = " + id + " AND a.site_id = " + siteId + " AND a.status != -1 "
);
if(!info.next()) { return; }

//항목
DataSet iinfo = new DataSet();
if(!"".equals(info.s("items")) && !"[]".equals(info.s("items"))) iinfo.unserialize(info.s("items"));


//목록
DataSet items = new DataSet();
for(int i = 1; i <= icnt; i++) {
	items.addRow();
	items.put("__ord", i);
	items.put("txt", iinfo.s("item" + i + "_txt"));
	items.put("var", iinfo.s("item" + i + "_var"));
}


//출력
p.setLayout(null);
p.setVar(info);
p.setLoop("items", items);
p.setVar("icnt", icnt);
p.print(out, "ktalk/call_template_content.html");


%>