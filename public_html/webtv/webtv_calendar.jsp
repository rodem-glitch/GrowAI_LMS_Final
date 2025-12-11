<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CodeDao code = new CodeDao();
WebtvDao webtv = new WebtvDao();
LessonDao lesson = new LessonDao();
LmCategoryDao category = new LmCategoryDao("webtv");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();
CourseDao course = new CourseDao();

//변수-검색년월
String year = m.rs("year", m.time("yyyy"));
String month = m.rs("month", m.time("MM"));
if(4 != year.length()) year = m.time("yyyy");
if(2 != month.length()) month = m.time("MM");
String thisMonth = year + "" + month;
String prevMonth = m.addDate("M", -1, thisMonth + "01", "yyyyMM");
String nextMonth = m.addDate("M", 1, thisMonth + "01", "yyyyMM");
String day = m.time("dd");
String date = year + month + day;

//변수-현재
String today = m.time("yyyyMMdd");
int time = m.parseInt(m.time("HHmmss"));

//목록-방송
DataSet tlist = webtv.query(
	" SELECT a.*, c.parent_id "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.open_date BETWEEN '" + prevMonth + "01000000' AND '" + nextMonth + "31235959' "
	+ " AND a.display_yn = 'Y' AND a.status = 1 "
	+ ("recomm".equals(m.rs("mode")) ? " AND a.recomm_yn = 'Y' " : "")
);
while(tlist.next()) {
	tlist.put("webtv_nm_conv", m.cutString(tlist.s("webtv_nm"), 56));
	tlist.put("subtitle_conv", m.nl2br(tlist.s("subtitle")));
	tlist.put("subtitle_conv2", m.nl2br(m.stripTags(tlist.s("subtitle"))));
	tlist.put("open_time", m.time("HH:mm", tlist.s("open_date")));
	tlist.put("open_day", m.time("yyyyMMdd", tlist.s("open_date")));
	tlist.put("open_block", 0 < m.diffDate("D", tlist.s("open_day"), today) || (0 == m.diffDate("D", tlist.s("open_day"), today) && time >= m.parseInt(m.time("HHmmss", tlist.s("open_date")))));
}

//목록-날짜
DataSet dlist = code.getMonthDays(year + month + "01", "yyyyMMdd");
DataSet list = new DataSet();
while(dlist.next()) {
	if(1 == dlist.i("weekday") || 7 == dlist.i("weekday")) continue;
	list.addRow();
	list.put("date", dlist.s("date"));
	list.put("type", dlist.s("type"));
	list.put("weekday", dlist.s("weekday"));
	list.put("day", m.time("d", dlist.s("date")));
	list.put("newline", dlist.i("weekday") == 6 ? "</tr><tr>" : "");
	list.put("font", dlist.i("type") == 2 ? "bold" : "normal");
//	list.put("type", dlist.i("weekday") == 1 && dlist.s("type") == "2" ? "4" : dlist.s("type"));
	list.put("year", m.time("yyyy", dlist.s("date")));
	list.put("month", m.time("MM", dlist.s("date")));
	list.put(".sub", tlist.search("open_day", list.s("date"), "="));
}

//출력
p.setLayout(ch);
p.setBody("webtv.webtv_calendar");
p.setVar("p_title", "방송 편성표");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("date_query", m.qs("year,month"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
//p.setVar("pagebar", lm.getPaging());
p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));

p.setVar("date_query", m.qs("year,month"));
p.setVar("prev_year", ("01".equals(month) ? m.time("yyyy", m.addDate("Y", -1, m.strToDate(date))) : year));
p.setVar("next_year", ("12".equals(month) ? m.time("yyyy", m.addDate("Y", 1, m.strToDate(date))) : year));
p.setVar("current_year", year);
p.setVar("prev_month", m.time("MM", prevMonth + "01"));
p.setVar("next_month", m.time("MM", nextMonth + "01"));
p.setVar("current_month", month);
//p.setLoop("fields", fields);

p.display();

%>