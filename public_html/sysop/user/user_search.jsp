<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

String mode = m.request("mode", "user");
int sid = m.ri("sid") == 0 ? siteId : m.ri("sid");

//객체
UserDao user = new UserDao();

//폼체크
f.addElement("s_kind", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	user.table + " a"
);
lm.setFields("a.*");
lm.addWhere("a.status = 1 AND a.site_id = " + sid);
if("super".equals(mode)) lm.addWhere("a.user_kind = 'S'");
lm.addSearch("a.user_kind", f.get("s_kind"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.login_id,a.user_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.request("ord")) ? m.request("ord") : "a.reg_date ASC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("kind_conv", m.getItem(list.s("user_kind"), user.kinds));
}

//출력
p.setLayout("pop");
p.setBody("user.user_search");
p.setVar("p_title", "회원 선택");
p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setVar("form_script", f.getScript());
p.setVar("mode", mode);
p.setVar("sid", sid);
p.setLoop("kind_list", m.arr2loop(user.kinds));
p.display();
%>