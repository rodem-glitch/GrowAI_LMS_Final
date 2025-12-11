<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(95, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseDao course = new CourseDao();
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
MCal mcal = new MCal(10);

//날짜
String today = m.time("yyyyMMdd");
DataSet dinfo = new DataSet(); dinfo.addRow();
dinfo.put("sd", m.time("yyyy-MM-dd", today));
dinfo.put("ed", m.time("yyyy-MM-dd", today));
dinfo.put("sw", m.time("yyyy-MM-dd", mcal.getWeekFirstDate(today)));
dinfo.put("ew", m.time("yyyy-MM-dd", mcal.getWeekLastDate(today)));
dinfo.put("sm", m.time("yyyy-MM-01", today));
dinfo.put("em", m.time("yyyy-MM-dd", mcal.getMonthLastDate(today)));
dinfo.put("sy", m.time("yyyy-01-01", today));
dinfo.put("ey", m.time("yyyy-12-31", today));
dinfo.put("s3y", m.time("yyyy-01-01", m.addDate("Y", -2, today, "yyyyMMdd")));
dinfo.put("e3y", m.time("yyyy-12-31", today));

//변수
DataSet methods = m.arr2loop(order.methods);
methods.first();
while(methods.next()) {
	methods.put("sum_price", 0);
	methods.put("sum_count", 0);
}

//폼입력
String sdate = m.rs("s_sdate", dinfo.s("sm"));
String edate = m.rs("s_edate", dinfo.s("em"));

//폼입력
f.addElement("s_sdate", sdate, "hname:'시작일'");
f.addElement("s_edate", edate, "hname:'종료일'");

f.addElement("s_year", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_type", null, null);
f.addElement("s_display", null, null);

//목록-통계
Hashtable<String, Double> priceMap = new Hashtable<String, Double>();
Hashtable<String, Integer> countMap = new Hashtable<String, Integer>();
DataSet stat = orderItem.query(
	"SELECT a.course_id, o.paymethod, SUM(a.pay_price) price, COUNT(*) cnt "
	+ " FROM " + orderItem.table + " a "
	+ " INNER JOIN " + order.table + " o ON a.order_id = o.id AND o.site_id = " + siteId + " AND o.status IN (1,3,4) "
	+ " LEFT JOIN " + course.table + " c ON a.product_id = c.id AND a.product_type = 'course'"
	+ " WHERE a.product_type = 'course' AND a.pay_price > 0 "
	+ ( !"".equals(sdate) ? " AND o.order_date >= '" + m.time("yyyyMMdd", sdate) + "' " : " " )
	+ ( !"".equals(edate) ? " AND o.order_date <= '" + m.time("yyyyMMdd", edate) + "' " : " " )
	+ ( !"".equals(f.get("s_year")) ? " AND c.year = " + f.get("s_year") + " " : " " )
	+ ( !"".equals(f.get("s_onofftype")) ? " AND c.onoff_type = '" + f.get("s_onofftype") + "' " : " " )
	+ ( !"".equals(f.get("s_type")) ? " AND c.course_type = '" + f.get("s_type") + "' " : " " )
	+ ( !"".equals(f.get("s_display")) ? " AND c.display_yn = '" + f.get("s_display") + "' " : " " )
	+ " GROUP BY a.course_id, o.paymethod "
);
while(stat.next()) {
	String key = stat.s("course_id") + "_" + stat.s("paymethod");
	priceMap.put(key, m.parseDouble(stat.s("price")));
	countMap.put(key, stat.i("cnt"));
}

//목록
double sumTotalPrice = 0;
int sumTotalCount = 0;
DataSet list = course.query(
	"SELECT a.*, SUM(oi.pay_price) pay_price "
	+ " FROM " + course.table + " a "
	+ " INNER JOIN " + orderItem.table + " oi ON oi.course_id = a.id AND oi.product_type = 'course' AND oi.pay_price > 0 "
	+ " INNER JOIN " + order.table + " o ON oi.order_id = o.id AND o.site_id = " + siteId + " AND o.status IN (1,3) "
	+ " WHERE a.status = 1 AND a.site_id = " + siteId + " "
	+ ( !"".equals(sdate) ? " AND o.order_date >= '" + m.time("yyyyMMdd", sdate) + "' " : " " )
	+ ( !"".equals(edate) ? " AND o.order_date <= '" + m.time("yyyyMMdd", edate) + "' " : " " )
	+ ( !"".equals(f.get("s_year")) ? " AND a.year = " + f.get("s_year") + " " : " " )
	+ ( !"".equals(f.get("s_onofftype")) ? " AND a.onoff_type = '" + f.get("s_onofftype") + "' " : " " )
	+ ( !"".equals(f.get("s_type")) ? " AND a.course_type = '" + f.get("s_type") + "' " : " " )
	+ ( !"".equals(f.get("s_display")) ? " AND a.display_yn = '" + f.get("s_display") + "' " : " " )
	+ " GROUP BY a.id "
	+ " ORDER BY SUM(oi.pay_price) DESC "
);
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 40));
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));
	list.put("price_conv", m.nf(list.i("price")));

	DataSet temp = new DataSet();
	double totalPrice = 0;
	int totalCount = 0;
	methods.first();
	while(methods.next()) {
		String key = list.s("id") + "_" + methods.s("id");
		Double price = priceMap.containsKey(key) ? priceMap.get(key) : 0.00;
		int count = countMap.containsKey(key) ? countMap.get(key) : 0;
		methods.put("price", price);
		methods.put("price_conv", m.nf(price, 0));
		methods.put("count", count);
		methods.put("count_conv", m.nf(count));

		methods.put("sum_price", methods.d("sum_price") + price);
		methods.put("sum_count", methods.i("sum_count") + count);
	
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

	sumTotalPrice += totalPrice;
	sumTotalCount += totalCount;
}
methods.first();
while(methods.next()) {
	double rate = 0.00;
	if(sumTotalPrice > 0) rate = methods.d("sum_price") * 100 / sumTotalPrice;
	methods.put("sum_price_rate", m.nf(rate, 2));
	methods.put("sum_price_conv", m.nf(methods.d("sum_price"), 0));
	methods.put("sum_count_conv", m.nf(methods.i("sum_count")));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	Vector<String> v = new Vector<String>();
	v.add("onoff_type_conv=>구분");
	v.add("course_nm=>과정명");
	v.add("price_conv=>수강료");
	v.add("total_price_conv=>전체(금액)");
	v.add("total_count_conv=>전체(횟수)");
	methods.first();
	while(methods.next()) {
		v.add(methods.s("id") + "_price=>" + methods.s("value") + "(금액)");
		v.add(methods.s("id") + "_count=>" + methods.s("value") + "(횟수)");
	}

	ExcelWriter ex = new ExcelWriter(response, "과정주문통계(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, (String [])v.toArray(new String[v.size()]), "과정주문통계 (" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//변수
int moduleCnt = methods.size();

//출력
p.setBody("stat.order_course");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("SYS_TABLE_WIDTH", 700 + (moduleCnt >= 2 ? (moduleCnt - 1) * 140 : 0));

p.setLoop("list", list);
p.setLoop("methods", methods);
p.setVar("sum_total_price", m.nf(sumTotalPrice,0));
p.setVar("sum_total_count", m.nf(sumTotalCount));

p.setLoop("onoff_types", m.arr2loop(course.onoffPackageTypes));
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("years", mcal.getYears());
p.setVar("this_year", m.time("yyyy"));
p.setVar("date", dinfo);
p.setVar("module_cnt", moduleCnt);
p.display();

%>