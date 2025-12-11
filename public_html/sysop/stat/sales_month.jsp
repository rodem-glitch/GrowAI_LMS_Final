<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(98, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
RefundDao refund = new RefundDao();
MCal mcal = new MCal(10);

//날짜
String today = m.time("yyyyMMdd");
DataSet dinfo = new DataSet(); dinfo.addRow();
dinfo.put("this_year", m.time("yyyy", today));
dinfo.put("this_month", m.time("MM", today));

//폼입력
String syear = m.rs("s_syear", dinfo.s("this_year"));
String smonth = m.rs("s_smonth", "01");
String eyear = m.rs("s_eyear", dinfo.s("this_year"));
String emonth = m.rs("s_emonth", "12");

String sdate = syear + smonth + "01";
String edate = eyear + emonth + "31";

//폼입력
f.addElement("s_syear", syear, "hname:'시작일(년)',  required:'Y'");
f.addElement("s_smonth", smonth, "hname:'시작일(월)',  required:'Y'");
f.addElement("s_eyear", eyear, "hname:'종료일(년)',  required:'Y'");
f.addElement("s_emonth", emonth, "hname:'종료일(월)',  required:'Y'");

dinfo.put("sdate_conv", m.time("yyyy년 MM월", sdate));
dinfo.put("edate_conv", m.time("yyyy년 MM월", eyear + emonth + "01"));

//목록-통계
Hashtable<String, Double> priceMap = new Hashtable<String, Double>();
Hashtable<String, Integer> countMap = new Hashtable<String, Integer>();
DataSet stat = order.query(
	"SELECT SUBSTR(order_date, 1, 6) order_date, SUM(pay_price) price, COUNT(*) cnt "
	+ " FROM " + order.table + " "
	+ " WHERE site_id = " + siteId + " AND status IN (1,3,4) "  //완료/부분환불
	+ " AND order_date >= '" + sdate + "' AND order_date <= '" + edate + "' "
	+ " GROUP BY SUBSTR(order_date, 1, 6) "
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
	"SELECT SUBSTR(a.refund_date, 1, 6) refund_date, SUM(a.refund_price) price, COUNT(*) cnt "
	+ " FROM " + refund.table + " a "
	+ " INNER JOIN " + orderItem.table + " i ON a.order_item_id = i.id "
	+ " INNER JOIN " + order.table + " o ON i.order_id = o.id AND o.site_id = " + siteId + " "
	+ " WHERE a.status = 2 "  //완료
	+ " AND a.refund_date >= '" + sdate + "000000' AND a.refund_date <= '" + edate + "235959' "
	+ " GROUP BY SUBSTR(a.refund_date, 1, 6) "
	+ " ORDER BY refund_date ASC "
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
boolean flag = true;
while(flag) {
	list.addRow();
	list.put("date", sdate);
	list.put("date_conv", m.time("yyyy년 MM월", sdate));
	list.put("month_conv", m.time("M월", sdate));

	String key = m.time("yyyyMM", sdate);
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

	sdate = m.addDate("M", 1, sdate, "yyyyMM01");
	flag = 0 <= m.diffDate("D", sdate, (eyear + emonth + "01"));
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

	ExcelWriter ex = new ExcelWriter(response, "월별매출통계(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, (String [])v.toArray(new String[v.size()]), "월별매출통계 (" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("stat.sales_month");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("sum_order_price", m.nf(sumPrice,0));
p.setVar("sum_order_count", m.nf(sumCount));
p.setVar("sum_refund_price", m.nf(rsumPrice,0));
p.setVar("sum_refund_count", m.nf(rsumCount));
p.setVar("sum_sales_price", m.nf(sumSalesPrice,0));

p.setLoop("years", mcal.getYears());
p.setLoop("months", mcal.getMonths());
p.setVar("date", dinfo);
p.display();

%>