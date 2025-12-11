<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
FreepassDao freepass = new FreepassDao();

//변수
String today = m.time("yyyyMMdd");

//폼입력
String style = m.rs("s_style", "webzine");
String ord = m.rs("ord", "a.request_edate DESC");
int listNum = 10;

//폼체크
f.addElement("s_style", style, null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("scid", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(listNum);
lm.setTable(freepass.table + " a");
lm.setFields(
	"a.* "
	+ " , ( CASE "
		+ " WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_request "
);
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.status = 1");
lm.addWhere("a.display_yn = 'Y'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("a.freepass_nm, a.content", f.get("s_keyword"), "LIKE");
lm.setOrderBy(ord);

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));
	list.put("request_block", list.b("is_request") && list.b("sale_yn"));
	list.put("ready_block", 0 > m.diffDate("D", list.s("request_sdate"), today));

	list.put("freepass_nm_conv", m.cutString(list.s("freepass_nm"), 48));

	if(!"".equals(list.s("freepass_file"))) {
		list.put("freepass_file_url", m.getUploadUrl(list.s("freepass_file")));
	} else {
		list.put("freepass_file_url", "/html/images/common/noimage_course.gif");
	}

	list.put("price_conv", list.i("price") > 0 ? m.nf(list.i("price")) + "원" : "무료");
	list.put("price_conv2", m.nf(list.i("price")));

	list.put("list_price_conv", m.nf(list.i("list_price")));
	list.put("list_price_block", list.i("list_price") > 0);

	list.put("free_block", 0 == list.i("price"));
	
	list.put("freepass_day_conv", m.nf(list.i("freepass_day")));
	list.put("limit_cnt_conv", 0 < list.i("limit_cnt") ? m.nf(list.i("limit_cnt")) + "회" : "무제한");
}

//출력
p.setLayout(ch);
p.setBody("course.freepass_list");
p.setVar("p_title", "프리패스");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.setVar(style + "_type", true);
p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));
p.setVar("style", style);

p.display();

%>