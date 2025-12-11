<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String type = m.rs("type", "recomm");
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 100;
int line = m.ri("line") > 0 ? m.ri("line") : 100;

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseTargetDao courseTarget = new CourseTargetDao();
LessonDao lesson = new LessonDao();

//변수
String today = m.time("yyyyMMdd");
String thisMonth = m.time("yyyyMM");
String prevMonth = m.addDate("M", -1, thisMonth + "01", "yyyyMM");
String nextMonth = m.addDate("M", 1, thisMonth + "01", "yyyyMM");

//목록-방송
//course.d(out);
DataSet list = course.query(
	" SELECT a.* "
	+ " , ( CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_request "
	+ ", ( SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status IN (1,3) ) user_cnt "
	+ ", l.start_url, l.lesson_type, l.content_width, l.content_height "
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
while(list.next()) {
	list.put("request_date", "-");
	if("R".equals(list.s("course_type"))) {
		list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));
		list.put("study_date", m.time(_message.get("format.date.dot"), list.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("study_edate")));
		list.put("ready_block", 0 > m.diffDate("D", list.s("request_sdate"), today));
	} else if("A".equals(list.s("course_type"))) {
		list.put("request_date", "상시");
		list.put("study_date", "상시");
	}

	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 24));
	list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
	list.put("content_conv", m.cutString(m.stripTags(list.s("content1")), 120));
	if(!"".equals(list.s("course_file"))) {
		list.put("course_file_url", m.getUploadUrl(list.s("course_file")));
	} else {
		list.put("course_file_url", "/html/images/common/noimage_course.gif");
	}
	list.put("request_block", "Y".equals(list.s("is_request")));
	list.put("price_conv", list.i("price") > 0 ? m.nf(list.i("price")) + "원" : "무료");

	list.put("class", list.i("__ord") % line == 1 ? "first" : "");
}

//출력
p.setLayout(null);
p.setBody("inc.course_month_list");

p.setLoop("list", list);
p.display();

%>