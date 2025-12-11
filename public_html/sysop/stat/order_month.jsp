<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(94, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
OrderDao order = new OrderDao();
MCal mcal = new MCal(10);

//날짜
String today = m.time("yyyyMMdd");
DataSet dinfo = new DataSet(); dinfo.addRow();
dinfo.put("this_year", m.time("yyyy", today));
dinfo.put("this_month", m.time("MM", today));

//변수
DataSet methods = m.arr2loop(order.methods);

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
	"SELECT SUBSTR(order_date, 1, 6) order_date, paymethod, SUM(pay_price) price, COUNT(*) cnt "
	+ " FROM " + order.table + " "
	+ " WHERE site_id = " + siteId + " AND status IN (1,3,4) "  //완료/부분환불
	+ " AND order_date >= '" + sdate + "' AND order_date <= '" + edate + "' "
	+ " GROUP BY SUBSTR(order_date, 1, 6), paymethod "
	+ " ORDER BY order_date ASC "
);
while(stat.next()) {
	String key = stat.s("order_date") + "_" + stat.s("paymethod");
	priceMap.put(key, m.parseDouble(stat.s("price")));
	countMap.put(key, stat.i("cnt"));
}

//목록-합계
double sumTotalPrice = 0;
int sumTotalCount = 0;
Hashtable<String, Double> sumPriceMap = new Hashtable<String, Double>();
Hashtable<String, Integer> sumCountMap = new Hashtable<String, Integer>();
DataSet sumList = order.query(
	"SELECT paymethod, SUM(pay_price) price, COUNT(*) cnt "
	+ " FROM " + order.table + " "
	+ " WHERE site_id = " + siteId + " AND status IN (1,3,4) "  //완료/부분환불
	+ " AND order_date >= '" + sdate + "' AND order_date <= '" + edate + "' "
	+ " GROUP BY paymethod "
	+ " ORDER BY paymethod ASC "
);
while(sumList.next()) {
	sumPriceMap.put(sumList.s("paymethod"), sumList.d("price"));
	sumCountMap.put(sumList.s("paymethod"), sumList.i("cnt"));
}
methods.first();
while(methods.next()) {
	String key = methods.s("id");
	Double price = sumPriceMap.containsKey(key) ? sumPriceMap.get(key) : 0.00;
	int count = sumCountMap.containsKey(key) ? sumCountMap.get(key) : 0;
	methods.put("sum_price", price);
	methods.put("sum_price_conv", m.nf(price,0));
	methods.put("sum_count", count);
	methods.put("sum_count_conv", m.nf(count));
	sumTotalPrice += price;
	sumTotalCount += count;
}

methods.first();
while(methods.next()) {
	double rate = 0.00;
	if(sumTotalPrice > 0) rate = methods.d("sum_price") * 100 / sumTotalPrice;
	methods.put("sum_price_rate", m.nf(rate,2));
}


//목록
DataSet list = new DataSet();
boolean flag = true;
while(flag) {
	list.addRow();
	list.put("date", sdate);
	list.put("date_conv", m.time("yyyy년 MM월", sdate));
	list.put("month_conv", m.time("M월", sdate));

	DataSet temp = new DataSet();
	double totalPrice = 0;
	int totalCount = 0;
	methods.first();
	while(methods.next()) {
		String key = m.time("yyyyMM", sdate) + "_" + methods.s("id");
		Double price = priceMap.containsKey(key) ? priceMap.get(key) : 0.00;
		int count = countMap.containsKey(key) ? countMap.get(key) : 0;
		methods.put("price", price);
		methods.put("price_conv", m.nf(price, 0));
		methods.put("count", count);
		methods.put("count_conv", m.nf(count));

		totalPrice += price;
		totalCount += count;
		temp.addRow(methods.getRow());

		list.put(methods.s("id") + "_price", methods.s("price_conv"));
		list.put(methods.s("id") + "_count", methods.s("count_conv"));
	}

	list.put(".sub", temp);
	list.put("total_price", totalPrice);
	list.put("total_price_conv", m.nf(totalPrice,0));
	list.put("total_count", totalCount);
	list.put("total_count_conv", m.nf(totalCount));

	sdate = m.addDate("M", 1, sdate, "yyyyMMdd");
	flag = 0 <= m.diffDate("D", sdate, (eyear + emonth + "01"));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	Vector<String> v = new Vector<String>();
	v.add("date_conv=>날짜");
	v.add("total_price_conv=>전체(금액)");
	v.add("total_count_conv=>전체(횟수)");
	methods.first();
	while(methods.next()) {
		v.add(methods.s("id") + "_price=>" + methods.s("value") + "(금액)");
		v.add(methods.s("id") + "_count=>" + methods.s("value") + "(횟수)");
	}

	ExcelWriter ex = new ExcelWriter(response, "월별주문통계(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, (String [])v.toArray(new String[v.size()]), "월별주문통계 (" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("stat.order_month");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setLoop("methods", methods);
p.setVar("sum_total_price", m.nf(sumTotalPrice,0));
p.setVar("sum_total_count", m.nf(sumTotalCount));

p.setLoop("years", mcal.getYears());
p.setLoop("months", mcal.getMonths());
p.setVar("date", dinfo);
p.setVar("module_cnt", methods.size());
p.display();

%>