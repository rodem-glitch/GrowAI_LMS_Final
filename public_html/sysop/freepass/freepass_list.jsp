<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

if(!Menu.accessible(130, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

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
lm.setTable(freepass.table + " a");
lm.setFields("a.*, (SELECT COUNT(*) FROM " + freepassUser.table + " WHERE freepass_id = a.id AND status = 1) freepass_user_cnt");
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
	list.put("freepass_user_cnt_conv", m.nf(list.i("freepass_user_cnt")));

	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), freepass.statusList));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "프리패스관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "freepass_nm=>프리패스명", "freepass_day=>사용기간", "content=>내용", "list_price=>정가", "price=>판매가", "limit_cnt=>사용횟수", "reg_date_conv=>등록일", "status_conv=>상태" }, "프리패스관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("freepass.freepass_list");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("list_total", lm.getTotalString());
p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(freepass.statusList));

p.display();

%>
