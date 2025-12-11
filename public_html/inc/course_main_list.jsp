<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//폼입력
String type = m.rs("type", "recomm");
String tpl = m.rs("tpl", "course_main_list");
int count = m.ri("cnt") > 0 ? m.ri("cnt") : 100;
int strlen = m.ri("strlen") > 0 ? m.ri("strlen") : 24;
int line = m.ri("line") > 0 ? m.ri("line") : 100;

String today = m.time("yyyyMMdd");

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseMainDao courseMain = new CourseMainDao();
CourseTutorDao courseTutor = new CourseTutorDao();
LmCategoryDao category = new LmCategoryDao("course");
LessonDao lesson = new LessonDao();

//목록
//course.d(out);
DataSet list = course.query(
	"SELECT a.*"
	+ " , ( CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + today + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' "
		+ " ELSE 'N' "
	+ " END ) is_request "
	+ ", ( SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status IN (1,3) ) user_cnt "
	+ ", l.start_url, l.lesson_type, l.content_width, l.content_height, c.category_nm "
	+ " FROM " + courseMain.table + " m INNER JOIN " + course.table + " a ON a.id = m.course_id "
	+ " LEFT JOIN " + lesson.table + " l ON a.sample_lesson_id = l.id "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
	+ " WHERE a.status = 1 AND m.site_id = " + siteId + " AND m.type = '" + type + "'"
	+ " ORDER BY m.sort ASC "
	, count
);
while(list.next()) {
	list.put("request_date", "-");
	if("R".equals(list.s("course_type"))) {
		list.put("is_regular", true);
		list.put("request_date", m.time(_message.get("format.date.dot"), list.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("request_edate")));
		list.put("study_date", m.time(_message.get("format.date.dot"), list.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), list.s("study_edate")));
		list.put("ready_block", !"".equals(list.s("request_sdate")) ? 0 > m.diffDate("D", list.s("request_sdate"), today) : false);
	} else if("A".equals(list.s("course_type"))) {
		list.put("is_regular", false);
		list.put("request_date", "상시");
		list.put("study_date", m.nf(list.i("lesson_day")) + "일");
	}

	list.put("course_nm_conv", m.cutString(list.s("course_nm"), strlen));
	list.put("subtitle_conv", m.nl2br(list.s("subtitle")));
	list.put("content_conv", m.cutString(m.stripTags(list.s("content1")), 120));
	if(!"".equals(list.s("course_file"))) {
		list.put("course_file_url", m.getUploadUrl(list.s("course_file")));
	} else {
		list.put("course_file_url", "/html/images/common/noimage_course.gif");
	}
	list.put("request_block", "Y".equals(list.s("is_request")));
	list.put("price_conv", list.i("price") > 0 ? m.nf(list.i("price")) + "원" : "무료");
	list.put("list_price_conv", m.nf(list.i("list_price")));
	list.put("list_price_block", list.i("list_price") > 0);
	
	list.put("is_online", "N".equals(list.s("onoff_type")));
	list.put("is_offline", "F".equals(list.s("onoff_type")));
	list.put("is_blend", "B".equals(list.s("onoff_type")));
	list.put("is_package", "P".equals(list.s("onoff_type")));
	list.put("onoff_type_conv", m.getValue(list.s("onoff_type"), course.onoffPackageTypesMsg));

	list.put("class", list.i("__ord") % line == 1 ? "first" : "");
	list.put("tutor_nm", courseTutor.getTutorSummary(list.i("id")));
}

//출력
p.setLayout(null);
if(new File(tplRoot + "/inc/course_main_" + type + "_list.html").exists()) {
	p.setBody("inc.course_main_" + type + "_list");
} else {
	p.setBody("inc." + tpl);
}
p.setLoop("list", list);
p.setVar("type_" + type, true);
p.display();

%>