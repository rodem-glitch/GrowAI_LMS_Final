<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(37, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ScheduleDao schedule = new ScheduleDao();
CodeDao code = new CodeDao();
CourseDao course = new CourseDao();

String type = m.rs("type", "day");
String year = m.rs("year", m.time("yyyy"));
String month = m.rs("month", m.time("MM"));
if(4 != year.length()) year = m.time("yyyy");
if(2 != month.length()) month = m.time("MM");
String thisMonth = year + "" + month;
String prevMonth = m.addDate("M", -1, thisMonth + "01", "yyyyMM");
String nextMonth = m.addDate("M", 1, thisMonth + "01", "yyyyMM");
String day = m.time("dd");
String date = year + month + day;

String time = "yyyyMMdd";
if("month".equals(type)) {
	month = "";
	time = "yyyyMM";
}

//목록
DataSet slist = schedule.find("start_date BETWEEN '" + prevMonth + "01000000' AND '" + nextMonth + "31235959' AND site_id = " + siteId + " AND status != -1");
while(slist.next()) {
	slist.put("sch_nm_conv", m.cutString(slist.s("sch_nm"), 56));
}

//목록-날짜
DataSet dlist = code.getMonthDays(year + month + "01", "yyyyMMdd");
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
//	list.put("type", dlist.i("weekday") == 1 && dlist.s("type") == "2" ? "4" : dlist.s("type"));
	list.put("year", m.time("yyyy", dlist.s("date")));
	list.put("month", m.time("MM", dlist.s("date")));
	list.put(".sub", slist.search("start_date", list.s("date"), "="));
}

/*
//개설과정
String[] wf = {"request_sdate", "request_edate", "study_sdate", "study_edate"};
DataSet steps = course.query(
	"SELECT a.* "
	+ " FROM " + course.table + " a "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 1 AND ((" + m.join(" LIKE '" + year + month + "%') OR (", wf) + " LIKE '" + year + month + "%'))"
);

Hashtable<String, DataSet> schedules = new Hashtable<String, DataSet>();

while(scheduleList.next()) {
	String key = m.time(time, scheduleList.s("start_date"));
	DataSet nodes = schedules.containsKey(key) ? (DataSet)schedules.get(key) : new DataSet();
	scheduleList.put("nm_conv", m.cutString(scheduleList.s("sch_nm"), "month".equals(type) ? 80 : 15));
	scheduleList.put("name", scheduleList.s("sch_nm"));
	scheduleList.put("date_conv", m.time("yyyy-MM-dd", scheduleList.s("start_date")));
//	scheduleList.put("type_conv", m.getItem(scheduleList.s("type"), schedule.typeList));
	scheduleList.put("pop_block", true);
	scheduleList.put("date_icon", "");
	scheduleList.put("step_str", "");
	scheduleList.put("date_title", "");
	//nodes.addRow(scheduleList.getRow());
	schedules.put(key, nodes);
}

DataSet fields = schedule.getfields();

TreeMap<String, DataSet> tmpSch = new TreeMap<String, DataSet>();

while(steps.next()) {
	steps.put("pop_block", false);
	fields.first();
	while(fields.next()) {
		String key = steps.s(fields.s("id"));
		if("month".equals(type) || m.time("yyyyMM",steps.s(fields.s("id"))).equals(year + month)) {
			DataSet nodes = tmpSch.containsKey(key) ? (DataSet)tmpSch.get(key) : new DataSet();
			steps.put("step_str", steps.s("year") + "/" + steps.s("step") + "기 ");
			steps.put("nm_conv", m.cutString(steps.s("step_str") + steps.s("step_nm"), "month".equals(type) ? 80 : 10));
			steps.put("name", steps.s("step_str") + steps.s("step_nm"));
			steps.put("date_title", fields.s("name"));
			steps.put("date_icon", "<b style='color:" + fields.s("color") + "'>" + fields.s("icon") + "&nbsp;</b>");
			steps.put("date_conv", m.time("yyyy-MM-dd", steps.s(fields.s("id"))));
			nodes.addRow(steps.getRow());
			tmpSch.put(key, nodes);
		}
	}
}

Iterator kt = tmpSch.keySet().iterator();
while(kt.hasNext()) {

	DataSet tmpList = (DataSet)tmpSch.get((String)kt.next());
	tmpList.first();
	while(tmpList.next()) {
		String key = m.time(time, tmpList.s("date_conv"));
		DataSet nodes = schedules.containsKey(key) ? (DataSet)schedules.get(key) : new DataSet();
		nodes.addRow(tmpList.getRow());
		schedules.put(key, nodes);
	}
}

DataSet list = new DataSet();
if("month".equals(type)) {
	for(int i=1; i<=12; i++) {
		list.addRow();
		list.put(".sub", schedules.containsKey(year + (i < 10 ? "0" + i : "" + i)) ? (DataSet)schedules.get(year + (i < 10 ? "0" + i :  "" + i)) : new DataSet());
		list.put("month", i);
	}
} else {
	list = code.getMonthDays(year + month + m.time("dd"), "yyyyMMdd");
	while(list.next()) {
		list.put(".sub", schedules.containsKey(list.s("date")) ? (DataSet)schedules.get(list.s("date")) : new DataSet());
		list.put("day", m.time("d", list.s("date")));
		list.put("newline", list.i("weekday") == 7 ? "</tr><tr>" : "");
		list.put("font", list.i("type") == 2 ? "bold" : "normal");
//		list.put("type", list.i("weekday") == 1 && list.s("type") == "2" ? "4" : list.s("type"));
		list.put("year", m.time("yyyy", list.s("date")));
		list.put("month", m.time("MM", list.s("date")));
	}
}
*/

//출력
p.setBody("schedule.schedule");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("y_query", m.qs("year"));
p.setVar("m_query", m.qs("month"));

p.setLoop("list", list);

p.setVar("date_query", m.qs("year,month"));
p.setVar("prev_year", ("01".equals(month) ? m.time("yyyy", m.addDate("Y", -1, m.strToDate(date))) : year));
p.setVar("next_year", ("12".equals(month) ? m.time("yyyy", m.addDate("Y", 1, m.strToDate(date))) : year));
p.setVar("current_year", year);
p.setVar("prev_month", m.time("MM", prevMonth + "01"));
p.setVar("next_month", m.time("MM", nextMonth + "01"));
p.setVar("current_month", month);
p.setVar("tab_class_" + type , "current");
p.setVar("month_block", "month".equals(type));
//p.setLoop("fields", fields);
p.display();

%>