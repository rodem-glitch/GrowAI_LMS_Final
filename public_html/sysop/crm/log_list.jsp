<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseUserDao courseUser = new CourseUserDao();
CourseUserLogDao courseUserLog = new CourseUserLogDao();
CourseDao course = new CourseDao();
LessonDao lesson = new LessonDao();

//폼체트
f.addElement("s_course_user_id", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(
	courseUserLog.table + " a "
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + lesson.table + " l ON a.lesson_id = l.id "
);
lm.setFields("a.*, c.course_nm course_nm_original, l.lesson_nm lesson_nm_original");
lm.addWhere("a.status = 1");
lm.addWhere("a.user_id = " + uid + "");
lm.addSearch("a.course_user_id", f.get("s_course_user_id"));
lm.setOrderBy("a.reg_date DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("progress_ratio_conv", m.nf(list.d("progress_ratio"), 1));
	//list.put("browser", courseUserLog.getBrowser(list.s("user_agent")));
	list.put("browser", list.s("user_agent"));
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", list.s("reg_date")));
	list.put("course_nm_conv", m.cutString(list.s("course_nm_original"), 13));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm_original"), 28));
}

//목록-과정
//courseUser.d(out);
DataSet courses = courseUser.query(
	"SELECT a.id, a.start_date, a.end_date, c.course_nm "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId
	+ " WHERE a.user_id = " + uid
	+ " ORDER BY a.start_date desc, c.course_nm asc "
);
while(courses.next()) {
	courses.put("start_date_conv", m.time("yyyy.MM.dd", courses.s("start_date")));
	courses.put("end_date_conv", m.time("yyyy.MM.dd", courses.s("end_date")));
	courses.put("course_nm_conv", m.cutString(courses.s("course_nm"), 60));
}

//출력
p.setLayout(ch);
p.setBody("crm.log_list");
p.setVar("p_title", "진도로그");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("courses", courses);
p.setVar("tab_log", "current");
p.setVar("tab_sub_course", "current");
p.display();

%>