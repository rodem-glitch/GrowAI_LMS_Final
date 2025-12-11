<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(130, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
String mode = m.rs("mode");
if("".equals(mode)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
FreepassDao freepass = new FreepassDao(siteId);
FreepassUserDao freepassUser = new FreepassUserDao(siteId);

//폼체크
f.addElement("s_status", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(freepass.table + " a");
lm.setFields("a.*");
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 20);
lm.addWhere("a.status > -1");
lm.addWhere("a.site_id = " + siteId);
lm.addSearch("a.status", f.get("s_status"));
if(!"".equals(m.rs("s_field"))) lm.addSearch(m.rs("s_field"), m.rs("s_keyword"), "LIKE");
else lm.addSearch("a.freepass_nm,a.content", m.rs("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("freepass_nm_conv", m.cutString(list.s("freepass_nm"), 60));
	list.put("freepass_day_conv", m.nf(list.i("freepass_day")));
	list.put("list_price_conv", m.nf(list.i("list_price")));
	list.put("price_conv", m.nf(list.i("price")));
	list.put("limit_cnt_conv", 0 < list.i("limit_cnt") ? m.nf(list.i("limit_cnt")) + "회" : "무제한");

	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), freepass.statusList));
}


//출력
p.setLayout("pop");
p.setVar("p_title", "프리패스선택");
p.setBody("freepass.freepass_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(freepass.statusList));

p.display();

%>