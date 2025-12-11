<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(99, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("course");
CourseDao course = new CourseDao();
CourseTutorDao courseTutor = new CourseTutorDao();
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
RefundDao refund = new RefundDao();
MCal mcal = new MCal(10);
UserDao user = new UserDao(isBlindUser);
TutorDao tutor = new TutorDao();

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

//폼입력
String sdate = m.rs("s_sdate", dinfo.s("sm"));
String edate = m.rs("s_edate", dinfo.s("em"));

//폼입력
f.addElement("s_sdate", sdate, "hname:'시작일'");
f.addElement("s_edate", edate, "hname:'종료일'");

f.addElement("s_category", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_type", null, null);
f.addElement("s_display", null, null);

//목록-환불통계
Hashtable<String, Double> rpriceMap = new Hashtable<String, Double>();
Hashtable<String, Integer> rcountMap = new Hashtable<String, Integer>();
DataSet rstat = refund.query(
	"SELECT i.course_id, SUM(a.refund_price) price, COUNT(*) cnt "
	+ " FROM " + refund.table + " a "
	+ " INNER JOIN " + orderItem.table + " i ON a.order_item_id = i.id AND i.product_type = 'course' AND i.pay_price > 0 "
	+ " INNER JOIN " + order.table + " o ON a.order_id = o.id AND o.site_id = " + siteId + " "
	+ " INNER JOIN " + course.table + " c ON i.course_id = c.id AND c.site_id = " + siteId + " "
	+ " WHERE a.status = 2 "
	+ ( !"".equals(sdate) ? " AND a.refund_date >= '" + m.time("yyyyMMdd000000", sdate) + "' " : " " )
	+ ( !"".equals(edate) ? " AND a.refund_date <= '" + m.time("yyyyMMdd235959", edate) + "' " : " " )
	+ ( !"".equals(f.get("s_year")) ? " AND c.year = " + f.get("s_year") + " " : " " )
	+ ( !"".equals(f.get("s_onofftype")) ? " AND c.onoff_type = '" + f.get("s_onofftype") + "' " : " " )
	+ ( !"".equals(f.get("s_type")) ? " AND c.course_type = '" + f.get("s_type") + "' " : " " )
	+ ( !"".equals(f.get("s_display")) ? " AND c.display_yn = '" + f.get("s_display") + "' " : " " )
	+ " GROUP BY i.course_id "
	+ " ORDER BY " + (!"".equals(m.rs("ord")) ? m.rs("ord") : "i.course_id ASC")
);
while(rstat.next()) {
	String key = rstat.s("course_id");
	rpriceMap.put(key, m.parseDouble(rstat.s("price")));
	rcountMap.put(key, rstat.i("cnt"));
}

//카테고리
DataSet categories = category.getList(siteId);
//개인정보조회
DataSet totlist = new DataSet();

//목록
//orderItem.d(out);
DataSet list = orderItem.query(
	"SELECT a.course_id, SUM(a.pay_price) price, COUNT(*) cnt, MAX(c.course_nm) course_nm, MAX(c.course_type) type, MAX(c.onoff_type) onoff_type, MAX(c.price) course_price "
	+ " FROM " + orderItem.table + " a "
	+ " INNER JOIN " + order.table + " o ON a.order_id = o.id AND o.site_id = " + siteId + " AND o.status IN (1,3,4) "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
	+ " WHERE a.product_type = 'course' AND a.pay_price > 0 "
	+ ( !"".equals(sdate) ? " AND o.order_date >= '" + m.time("yyyyMMdd", sdate) + "' " : " " )
	+ ( !"".equals(edate) ? " AND o.order_date <= '" + m.time("yyyyMMdd", edate) + "' " : " " )
	+ ( !"".equals(f.get("s_year")) ? " AND c.year = " + f.get("s_year") + " " : " " )
	+ ( !"".equals(f.get("s_onofftype")) ? " AND c.onoff_type = '" + f.get("s_onofftype") + "' " : " " )
	+ ( !"".equals(f.get("s_type")) ? " AND c.course_type = '" + f.get("s_type") + "' " : " " )
	+ ( !"".equals(f.get("s_display")) ? " AND c.display_yn = '" + f.get("s_display") + "' " : " " )
	+ ( !"".equals(f.get("s_category")) ? " AND c.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )" : " ")
	+ " GROUP BY a.course_id "
	+ " ORDER BY " + (!"".equals(m.rs("ord")) ? m.rs("ord") : "price DESC")
);

double sumPrice = 0.0;
int sumCount = 0;
double rsumPrice = 0.0;
int rsumCount = 0;
double sumSalesPrice = 0.0;
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 60));
	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));
	list.put("price_conv", m.nf(list.i("course_price")));

	String key = list.s("course_id");
	Double price = list.getDouble("price");
	int count = list.i("cnt");
	Double rprice = rpriceMap.containsKey(key) ? rpriceMap.get(key) : 0.00;
	int rcount = rcountMap.containsKey(key) ? rcountMap.get(key) : 0;
	Double salesPrice = price - rprice;

	sumPrice += price;
	sumCount += count;
	rsumPrice += rprice;
	rsumCount += rcount;
	sumSalesPrice += salesPrice;

	DataSet tlist = courseTutor.query(
			"SELECT b.*"
			+ " FROM " + courseTutor.table + " a"
			+ " JOIN " + tutor.table + " b ON b.user_id = a.user_id"
			+ " WHERE a.course_id = " + list.i("course_id")
			+ " ORDER BY b.sort ASC, b.tutor_nm ASC "
	);
	String name = "";
	while(tlist.next()) {
		user.maskInfo(tlist);
		if("".equals(name)) name += tlist.s("tutor_nm");
		else name += ", " + tlist.s("tutor_nm");
	}
	list.put("tutor_nm_conv", name);
	totlist.addAll(tlist);

	//list.put("tutor_nm_conv", courseTutor.getTutorName(list.i("course_id")));
	list.put("order_price_conv", m.nf(price,0));
	list.put("order_count_conv", m.nf(count));
	list.put("refund_price_conv", m.nf(rprice,0));
	list.put("refund_count_conv", m.nf(rcount));
	list.put("sales_price_conv", m.nf(salesPrice,0));
	//user.maskInfo(list);
}

//기록-개인정보조회
if(totlist.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, totlist.size(), "이러닝 운영", totlist);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	Vector<String> v = new Vector<String>();
	v.add("course_nm=>과정명");
	v.add("tutor_nm_conv=>담당강사");
	v.add("price_conv=>수강료");
	v.add("order_price_conv=>주문 금액");
	v.add("order_count_conv=>주문 건수");
	v.add("refund_price_conv=>환불 금액");
	v.add("refund_count_conv=>환불 건수");
	v.add("sales_price_conv=>매출 금액");

	ExcelWriter ex = new ExcelWriter(response, "과정매출통계(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, (String [])v.toArray(new String[v.size()]), "과정매출통계 (" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("stat.sales_course");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("sum_order_price", m.nf(sumPrice,0));
p.setVar("sum_order_count", m.nf(sumCount));
p.setVar("sum_refund_price", m.nf(rsumPrice,0));
p.setVar("sum_refund_count", m.nf(rsumCount));
p.setVar("sum_sales_price", m.nf(sumSalesPrice,0));

p.setLoop("onoff_types", m.arr2loop(course.onoffPackageTypes));
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("categories", categories);
p.setVar("this_year", m.time("yyyy"));
p.setVar("date", dinfo);
p.display();

%>