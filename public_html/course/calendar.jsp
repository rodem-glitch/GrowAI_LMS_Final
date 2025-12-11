<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CodeDao code = new CodeDao();
LessonDao lesson = new LessonDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseTargetDao courseTarget = new CourseTargetDao();
LmCategoryDao category = new LmCategoryDao("course");

//폼입력
String style = "list";
String type = m.rs("type");
String query = m.rs("query", "study");
if(!m.inArray(query, "study,request")) query = "study";
if(!"".equals(m.rs("s_style"))) style = m.rs("s_style");
int categoryId = m.ri("cid", siteId * -1);

//변수
String today = m.time("yyyyMMdd");
String year = m.rs("year"); if(4 != year.length() || 2000 > m.parseInt(year) || 3000 < m.parseInt(year)) year = m.time("yyyy");
String month = m.strrpad(m.rs("month"), 2, "0"); if(2 != month.length() || 1 > m.parseInt(month) || 12 < m.parseInt(month)) month = m.time("MM");
String thisMonth = year + month;
String prevMonth = m.addDate("M", -1, thisMonth + "01", "yyyyMM");
String nextMonth = m.addDate("M", 1, thisMonth + "01", "yyyyMM");
String day = m.time("dd");
String date = year + month + day;
String subIdx = (categoryId > 0 ? category.getSubIdx(siteId, m.ri("scid") > 0 ? m.ri("scid") : categoryId) : "0");

//목록
//course.d(out);
DataSet clist = course.query(
	" SELECT a.*, l.start_url, l.lesson_type, l.content_width, l.content_height, c.category_nm "
	+ " , ( CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_request "
	+ " , ( CASE "
		+ " WHEN a.course_type = 'R' AND a.request_sdate > '" + today + "' THEN 'Y' ELSE 'N' "
	+ " END ) is_prev "
	+ " , ( CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN a.study_sdate AND a.study_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_study "
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status NOT IN (-1, -4)) user_cnt "
	+ " FROM " + course.table + " a "
	+ " LEFT JOIN " + lesson.table + " l ON a.sample_lesson_id = l.id "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
	+ " WHERE a.site_id = " + siteId + " AND a.course_type = 'R' AND a.close_yn = 'N' AND a.display_yn = 'Y' AND a.status = 1 "
	+ " AND a." + query + "_edate >= '" + thisMonth + "01' AND a." + query + "_sdate <= '" + thisMonth + "31' "

	+ (!"".equals(type) ? " AND a.onoff_type " + ("on".equals(type) ? "=" : "!=") + " 'N'" : "")

	+ " AND (a.target_yn = 'N'"
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = a.id AND group_id IN (" + userGroups + "))"
		: "")
	+ ")"
	+ (categoryId > 0 ? " AND a.category_id IN (" + (!"".equals(subIdx) ? subIdx : "0") + ") " : "")
	+ " ORDER BY a." + query + "_sdate ASC "
);
while(clist.next()) {
	clist.put("course_nm_conv", m.cutString(clist.s("course_nm"), 56));
	clist.put("onoff_type_conv", m.getValue(clist.s("onoff_type"), course.onoffPackageTypesMsg));

	clist.put("request_date", "-");
	if("R".equals(clist.s("course_type"))) {
		clist.put("is_regular", true);
		clist.put("request_date", m.time(_message.get("format.date.dot"), clist.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), clist.s("request_edate")));
		clist.put("study_date", m.time(_message.get("format.date.dot"), clist.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), clist.s("study_edate")));
		clist.put("ready_day", m.diffDate("D", clist.s("request_sdate"), today));
		clist.put("ready_block", 0 > clist.i("ready_day"));
	} else if("A".equals(clist.s("course_type"))) {
		clist.put("is_regular", false);
		clist.put("request_date", _message.get("list.course.types.A"));
		clist.put("study_date", _message.get("list.course.types.A"));
		clist.put("ready_day", 0);
		clist.put("ready_block", false);
	}

	clist.put("request_block",
		(
			("Y".equals(clist.s("is_request")) && "N".equals(clist.s("limit_people_yn")))
			|| ("Y".equals(clist.s("is_request")) && "Y".equals(clist.s("limit_people_yn")) && clist.i("limit_people") > clist.i("user_cnt"))
		) && !clist.b("close_yn") && clist.b("sale_yn")
	);

	if("R".equals(clist.s("course_type")) && !clist.b("is_request") && !clist.b("is_prev")) {
		clist.put("request_status", "end");
		clist.put("request_status_message", "정규 신청기간이 경과했습니다.");
	} else if(clist.b("limit_people_yn") && clist.i("limit_people") <= clist.i("user_cnt")) {
		clist.put("request_status", "end");
		clist.put("request_status_message", "수강제한인원을 초과했습니다.");
	} else if(clist.b("close_yn")) {
		clist.put("request_status", "end");
		clist.put("request_status_message", "과정이 종료되었습니다.");
	} else if(!clist.b("sale_yn")) {
		clist.put("request_status", "ready");
		clist.put("request_status_message", "판매가 중지되었습니다.");
	} else if("R".equals(clist.s("course_type")) && clist.b("is_prev")) {
		clist.put("request_status", "ready");
		clist.put("request_status_message", "정규 신청기간 전입니다.");
	} else {
		clist.put("request_status", "request");
		clist.put("request_status_message", "신청이 가능합니다.");
	}
	
	clist.put("price_conv", clist.i("price") > 0 ? siteinfo.s("currency_prefix") + m.nf(clist.i("price")) + siteinfo.s("currency_suffix") : _message.get("payment.unit.free"));
	clist.put("price_conv2", m.nf(clist.i("price")));

	clist.put("content_width_conv", clist.i("content_width") + 20);
	clist.put("content_height_conv", clist.i("content_height") + 23);
	
}

//목록-날짜
DataSet dlist = code.getMonthDays(year + month + m.time("dd"), "yyyyMMdd");
DataSet list = new DataSet();
while(dlist.next()) {
	//if(1 == dlist.i("weekday") || 7 == dlist.i("weekday")) continue;
	list.addRow();
	list.put("date", dlist.s("date"));
	list.put("type", dlist.s("type"));
	list.put("weekday", dlist.s("weekday"));
	list.put("day", m.time("d", dlist.s("date")));
	list.put("newline", dlist.i("weekday") == 7 ? "</tr><tr>" : "");
	list.put("font", dlist.i("type") == 2 ? "bold" : "normal");
	//list.put("type", dlist.i("weekday") == 1 && dlist.s("type") == "2" ? "4" : dlist.s("type"));
	list.put("year", m.time("yyyy", dlist.s("date")));
	list.put("month", m.time("MM", dlist.s("date")));

	DataSet requestStart = clist.search("request_sdate", list.s("date"), "=");
	DataSet requestEnd = clist.search("request_edate", list.s("date"), "=");
	DataSet studyStart = clist.search("study_sdate", list.s("date"), "=");
	DataSet studyEnd = clist.search("study_edate", list.s("date"), "=");

	list.put(".request_start", requestStart);
	list.put(".request_end", requestEnd);
	list.put(".study_start", studyStart);
	list.put(".study_end", studyEnd);

	list.put("sub_block", 0 < requestStart.size() || 0 < requestEnd.size() || 0 < studyStart.size() || 0 < studyEnd.size());
}

//출력
//ch = "yanolja";
p.setLayout(ch);
p.setBody("course.calendar");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
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
p.setVar("list_type", "list".equals(style));
p.setVar("calendar_type", "calendar".equals(style));
p.setVar("style", style);
//p.setLoop("fields", fields);

p.display();

%>