<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

if(!(Menu.accessible(6, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//폼체크
f.addElement("s_site", siteinfo.i("id"), null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//객체
BoardDao board = new BoardDao();

//목록
ListManager lm = new ListManager(jndi);
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum(999);
lm.setTable(board.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addSearch("a.board_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.board_nm, a.code", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.site_id ASC, a.id ASC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("board_nm_conv", m.cutString(list.s("board_nm"), 50));
	list.put("board_type_conv", m.getItem(list.s("board_type"), board.types));
	list.put("status_conv", m.getItem(list.s("status"), board.statusList));
}

if("json".equals(m.rs("mode"))) {
	response.setContentType("application/json;charset=utf-8");
	out.print(list.serialize());
	return;
}

//출력
p.setBody("board.board_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
//p.setVar("pagebar", lm.getPaging());

p.setLoop("types", m.arr2loop(board.types));
p.setLoop("status_list", m.arr2loop(board.statusList));
p.display();

%>