<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
GroupDao group = new GroupDao();

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setFields("a.*");
lm.setListNum(20000);
lm.setTable(group.table + " a");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
if(!"".equals(m.rs("idx"))) lm.addWhere("a.id NOT IN (" + m.join(",", m.rs("idx").split(",")) + ")");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.group_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy("a.group_nm ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {}

//출력
p.setLayout("pop");
p.setBody("user.group_select");
p.setVar("p_title", "회원그룹 관리");
p.setVar("form_script", f.getScript());
p.setVar("list_query", m.qs("idx"));
p.setVar("query", m.qs());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.display();

%>