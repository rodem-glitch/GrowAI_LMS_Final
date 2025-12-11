<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.text.DecimalFormat" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
FreepassDao freepass = new FreepassDao();

//정보
DataSet info = freepass.query(
	"SELECT a.* "
	+ ", (CASE WHEN '" + m.time("yyyyMMdd") + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' ELSE 'N' END) is_request "
	+ " FROM " + freepass.table + " a "
	+ " WHERE a.id = " + id + " AND a.site_id = "+ siteId +" AND a.status = 1 "
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

info.put("request_date", m.time(_message.get("format.date.dot"), info.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), info.s("request_edate")));
info.put("request_block", info.b("is_request") && info.b("sale_yn"));
info.put("ready_block", 0 > m.diffDate("D", info.s("request_sdate"), m.time("yyyyMMdd")));

if(!"".equals(info.s("freepass_file"))) {
	info.put("freepass_file_url", m.getUploadUrl(info.s("freepass_file")));
} else {
	info.put("freepass_file_url", "/html/images/common/noimage_course.gif");
}

info.put("price_conv", m.nf(info.i("price")));
info.put("list_price_conv", m.nf(info.i("list_price")));
info.put("list_price_block", info.i("list_price") > 0);

info.put("free_block", 0 == info.i("price"));
	
info.put("freepass_day_conv", m.nf(info.i("freepass_day")));
info.put("limit_cnt_conv", 0 < info.i("limit_cnt") ? m.nf(info.i("limit_cnt")) + "회" : "무제한");

//출력
p.setLayout(ch);
p.setBody("course.freepass_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setVar("buy_block", info.i("price") > 0);

p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));
p.display();

%>