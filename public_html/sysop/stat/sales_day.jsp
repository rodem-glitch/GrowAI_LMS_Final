<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.regex.*" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(65, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
RefundDao refund = new RefundDao();
MCal mcal = new MCal();

//날짜
String today = m.time("yyyyMMdd");
DataSet dinfo = new DataSet(); dinfo.addRow();
dinfo.put("sd", m.time("yyyy-MM-dd", today));
dinfo.put("ed", m.time("yyyy-MM-dd", today));
dinfo.put("sw", m.time("yyyy-MM-dd", mcal.getWeekFirstDate(today)));
dinfo.put("ew", m.time("yyyy-MM-dd", mcal.getWeekLastDate(today)));
dinfo.put("sm", m.time("yyyy-MM-01", today));
dinfo.put("em", m.time("yyyy-MM-dd", mcal.getMonthLastDate(today)));

//폼입력
String sdate = m.rs("s_sdate", dinfo.s("sm"));
String edate = m.rs("s_edate", dinfo.s("em"));
Pattern pattern = Pattern.compile("^[0-9]{4}-[0-1]{1}[0-9]{1}-[0-3]{1}[0-9]{1}$");
if(!pattern.matcher(sdate).matches()) sdate = dinfo.s("sm");
if(!pattern.matcher(edate).matches()) edate = dinfo.s("em");

//검색기간제한
if(93 < m.diffDate("D", sdate, edate)) {
	m.jsAlert("1회 검색 시 최대 3개월간 조회 가능합니다.");
	edate = m.addDate("D", 93, sdate, "yyyy-MM-dd");
}

//폼입력
f.addElement("s_sdate", sdate, "hname:'시작일',  required:'Y'");
f.addElement("s_edate", edate, "hname:'종료일',  required:'Y'");

dinfo.put("sdate_conv", m.time("yyyy.MM.dd", sdate));
dinfo.put("edate_conv", m.time("yyyy.MM.dd", edate));

//목록-통계
Hashtable<String, Double> priceMap = new Hashtable<String, Double>();
Hashtable<String, Integer> countMap = new Hashtable<String, Integer>();
DataSet stat = order.query(
	"SELECT order_date, SUM(pay_price) price, COUNT(*) cnt "
	+ " FROM " + order.table + " "
	+ " WHERE site_id = " + siteId + " AND status IN (1,3,4) "  //완료/부분환불
	+ " AND order_date >= '" + m.time("yyyyMMdd", sdate) + "' AND order_date <= '" + m.time("yyyyMMdd", edate) + "' "
	+ " GROUP BY order_date "
	+ " ORDER BY order_date ASC "
);
while(stat.next()) {
	String key = stat.s("order_date");
	priceMap.put(key, m.parseDouble(stat.s("price")));
	countMap.put(key, stat.i("cnt"));
}

//목록-환불통계
Hashtable<String, Double> rpriceMap = new Hashtable<String, Double>();
Hashtable<String, Integer> rcountMap = new Hashtable<String, Integer>();
DataSet rstat = refund.query(
	"SELECT SUBSTRING(a.refund_date, 1, 8) refund_date, SUM(a.refund_price) price, COUNT(*) cnt "
	+ " FROM " + refund.table + " a "
	+ " INNER JOIN " + orderItem.table + " i ON a.order_item_id = i.id "
	+ " INNER JOIN " + order.table + " o ON i.order_id = o.id AND o.site_id = " + siteId + " "
	+ " WHERE a.status = 2 "  //완료
	+ " AND a.refund_date >= '" + m.time("yyyyMMdd000000", sdate) + "' AND a.refund_date <= '" + m.time("yyyyMMdd235959", edate) + "' "
	+ " GROUP BY SUBSTRING(a.refund_date, 1, 8), a.refund_method "
	+ " ORDER BY a.refund_date ASC "
);
while(rstat.next()) {
	String key = rstat.s("refund_date");
	rpriceMap.put(key, m.parseDouble(rstat.s("price")));
	rcountMap.put(key, rstat.i("cnt"));
}


//목록
double sumPrice = 0.0;
int sumCount = 0;
double rsumPrice = 0.0;
int rsumCount = 0;
double sumSalesPrice = 0.0;
DataSet list = new DataSet();
int diffCnt = m.diffDate("D", sdate, edate);
for(int i = diffCnt; i >= 0; i--) {
	list.addRow();
	list.put("date", sdate);
	list.put("date_conv", m.time("yyyy.MM.dd", sdate));
	list.put("day_conv", m.time("d", sdate));

	String key = m.time("yyyyMMdd", sdate);
	Double price = priceMap.containsKey(key) ? priceMap.get(key) : 0.00;
	int count = countMap.containsKey(key) ? countMap.get(key) : 0;
	Double rprice = rpriceMap.containsKey(key) ? rpriceMap.get(key) : 0.00;
	int rcount = rcountMap.containsKey(key) ? rcountMap.get(key) : 0;
	Double salesPrice = price - rprice;

	sumPrice += price;
	sumCount += count;
	rsumPrice += rprice;
	rsumCount += rcount;
	sumSalesPrice += salesPrice;

	list.put("order_price_conv", m.nf(price,0));
	list.put("order_count_conv", m.nf(count));
	list.put("refund_price_conv", m.nf(rprice,0));
	list.put("refund_count_conv", m.nf(rcount));
	list.put("sales_price", salesPrice);
	list.put("sales_price_conv", m.nf(salesPrice,0));

	sdate = m.addDate("D", 1, sdate, "yyyy-MM-dd");
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	Vector<String> v = new Vector<String>();
	v.add("date_conv=>날짜");
	v.add("order_price_conv=>주문 금액");
	v.add("order_count_conv=>주문 건수");
	v.add("refund_price_conv=>환불 금액");
	v.add("refund_count_conv=>환불 건수");
	v.add("sales_price_conv=>매출 금액");

	ExcelWriter ex = new ExcelWriter(response, "일별매출통계(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, (String [])v.toArray(new String[v.size()]), "일별매출통계 (" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("stat.sales_day");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("sum_order_price", m.nf(sumPrice,0));
p.setVar("sum_order_count", m.nf(sumCount));
p.setVar("sum_refund_price", m.nf(rsumPrice,0));
p.setVar("sum_refund_count", m.nf(rsumCount));
p.setVar("sum_sales_price", m.nf(sumSalesPrice,0));

p.setVar("date", dinfo);
p.display();

%>