<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CodeDao code = new CodeDao();
LessonDao lesson = new LessonDao();
CourseDao course = new CourseDao();
CourseTargetDao courseTarget = new CourseTargetDao();

//변수
String year = m.rs("year"); if(4 != year.length() || 2000 > m.parseInt(year) || 3000 < m.parseInt(year)) year = m.time("yyyy");
String month = m.strrpad(m.rs("month"), 2, "0"); if(2 != month.length() || 1 > m.parseInt(month) || 12 < m.parseInt(month)) month = m.time("MM");
String thisMonth = year + month;
String prevMonth = m.addDate("M", -1, thisMonth + "01", "yyyyMM");
String nextMonth = m.addDate("M", 1, thisMonth + "01", "yyyyMM");
String day = m.time("dd");
String date = year + month + day;

//목록-방송
//course.d(out);
DataSet clist = course.query(
	" SELECT a.*, l.start_url, l.lesson_type, l.content_width, l.content_height "
	+ " FROM " + course.table + " a "
	+ " LEFT JOIN " + lesson.table + " l ON a.sample_lesson_id = l.id "
	+ " WHERE a.site_id = " + siteId + " AND a.course_type = 'R' AND a.close_yn = 'N' AND a.display_yn = 'Y' AND a.status = 1 "
	+ " AND a.request_edate >= '" + thisMonth + "01' AND a.request_sdate <= '" + thisMonth + "31' "

	+ " AND (a.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = a.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"

	+ " ORDER BY a.request_sdate ASC "
);
while(clist.next()) {
	clist.put("course_nm_conv", m.cutString(clist.s("course_nm"), 56));
	clist.put("onoff_type_conv", m.getItem(clist.s("onoff_type"), course.onoffPackageTypes));

	clist.put("request_date", "-");
	if("R".equals(clist.s("course_type"))) {
		clist.put("is_regular", true);
		clist.put("request_date", m.time(_message.get("format.date.dot"), clist.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), clist.s("request_edate")));
		clist.put("study_date", m.time(_message.get("format.date.dot"), clist.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), clist.s("study_edate")));
		clist.put("ready_block", 0 > m.diffDate("D", clist.s("request_sdate"), m.time("yyyyMMdd")));
	} else if("A".equals(clist.s("course_type"))) {
		clist.put("is_regular", false);
		clist.put("request_date", "상시");
		clist.put("study_date", "상시");
		clist.put("ready_block", false);
	}

	clist.put("price_conv", clist.i("price") > 0 ? m.nf(clist.i("price")) + "원" : "무료");
	clist.put("price_conv2", m.nf(clist.i("price")));

	clist.put("content_width_conv", clist.i("content_width") + 20);
	clist.put("content_height_conv", clist.i("content_height") + 23);
	
}

//출력
p.setLayout(ch);
p.setBody("mobile.course_calendar");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("clist", clist);
p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));

p.setVar("date_query", m.qs("year,month"));
//p.setVar("prev_year", ("01".equals(month) ? m.time("yyyy", m.addDate("Y", -1, m.strToDate(date))) : year));
//p.setVar("next_year", ("12".equals(month) ? m.time("yyyy", m.addDate("Y", 1, m.strToDate(date))) : year));
p.setVar("prev_year", prevMonth.substring(0, 4));
p.setVar("next_year", nextMonth.substring(0, 4));
p.setVar("current_year", year);
//p.setVar("prev_month", m.time("MM", m.addDate("M", -1, m.strToDate(date))));
//p.setVar("next_month", m.time("MM", m.addDate("M", 1, m.strToDate(date))));
p.setVar("prev_month", prevMonth.substring(4));
p.setVar("next_month", nextMonth.substring(4));
p.setVar("current_month", month);

p.setVar("year", year);
p.setVar("month", month);
//p.setLoop("fields", fields);

p.display();

%>