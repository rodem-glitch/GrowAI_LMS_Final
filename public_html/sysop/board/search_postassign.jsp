<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }
if(!adminBlock) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int pid = m.ri("pid");
if(1 > pid) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
UserDao user = new UserDao();
PostLogDao postLog = new PostLogDao(siteId);

//처리
if("assign".equals(m.rs("mode"))) {
	if(!postLog.removeAllLog(pid, "assign") || !postLog.log(m.ri("uid"), pid, "assign")) { }
	m.jsReplace("answer.jsp?" + m.qs("mode,uid"), "parent.opener");
	m.js("parent.window.close();");
	return;
}

//폼체크
f.addElement("s_level", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(user.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId);
lm.addWhere("a.user_kind IN ('A', 'S')");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.user_nm,a.login_id", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	//list.put("reg_date", m.time("yyyy-MM-dd", list.s("reg_date")));
}

//출력
p.setLayout("pop");
p.setBody("board.search_postassign");
p.setVar("p_title", "담당자 선택");
p.setVar("form_script", f.getScript());
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.display();

%>