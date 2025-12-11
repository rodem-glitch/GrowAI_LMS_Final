<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.regex.*" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(63, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
OrderDao order = new OrderDao();
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

//변수
DataSet methods = m.arr2loop(order.methods);

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
f.addElement("s_sdate", sdate, "hname:'시작일', required:'Y'");
f.addElement("s_edate", edate, "hname:'종료일', required:'Y'");

dinfo.put("sdate_conv", m.time("yyyy.MM.dd", sdate));
dinfo.put("edate_conv", m.time("yyyy.MM.dd", edate));

//목록-통계
Hashtable<String, Double> priceMap = new Hashtable<String, Double>();
Hashtable<String, Integer> countMap = new Hashtable<String, Integer>();
DataSet stat = order.query(
	"SELECT order_date, paymethod, SUM(pay_price) price, COUNT(*) cnt "
	+ " FROM " + order.table + " "
	+ " WHERE site_id = " + siteId + " AND status IN (1,3,4) "  //완료/부분환불
	+ " AND order_date >= '" + m.time("yyyyMMdd", sdate) + "' AND order_date <= '" + m.time("yyyyMMdd", edate) + "' "
	+ " GROUP BY order_date, paymethod "
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
	+ " WHERE site_id = " + siteId + " AND status IN (1,3,4) "  //완료/부분환불/전액환불
	+ " AND order_date >= '" + m.time("yyyyMMdd", sdate) + "' AND order_date <= '" + m.time("yyyyMMdd", edate) + "' "
	+ " GROUP BY paymethod "
	+ " ORDER BY order_date ASC "
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
int diffCnt = m.diffDate("D", sdate, edate);
for(int i = diffCnt; i >= 0; i--) {
	list.addRow();
	list.put("date", sdate);
	list.put("date_conv", m.time("yyyy.MM.dd", sdate));
	list.put("day_conv", m.time("d", sdate));

	DataSet temp = new DataSet();
	double totalPrice = 0;
	int totalCount = 0;
	methods.first();
	while(methods.next()) {
		String key = m.time("yyyyMMdd", sdate) + "_" + methods.s("id");
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

	sdate = m.addDate("D", 1, sdate, "yyyy-MM-dd");
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

	ExcelWriter ex = new ExcelWriter(response, "일별주문통계(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, (String [])v.toArray(new String[v.size()]), "일별주문통계 (" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("stat.order_day");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setLoop("methods", methods);
p.setVar("sum_total_price", m.nf(sumTotalPrice,0));
p.setVar("sum_total_count", m.nf(sumTotalCount));

p.setVar("date", dinfo);
p.setVar("module_cnt", methods.size());
p.display();

%>