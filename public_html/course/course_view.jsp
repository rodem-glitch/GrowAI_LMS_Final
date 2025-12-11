<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.text.DecimalFormat" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
CourseDao course = new CourseDao();
//CourseCategoryDao category = new CourseCategoryDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseUserDao courseUser = new CourseUserDao();
CourseTargetDao courseTarget = new CourseTargetDao();
LessonDao lesson = new LessonDao();

TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();
BookDao book = new BookDao();
CourseBookDao courseBook = new CourseBookDao();
UserDao user = new UserDao();

CourseLessonDao courseLesson = new CourseLessonDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseSectionDao courseSection = new CourseSectionDao();
CoursePackageDao coursePackage = new CoursePackageDao();

ExamDao exam = new ExamDao();
HomeworkDao homework = new HomeworkDao();
ForumDao forum = new ForumDao();
SurveyDao survey = new SurveyDao();

//정보
DataSet info = course.query(
	"SELECT a.* "
	+ ", (CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + m.time("yyyyMMdd") + "' BETWEEN a.request_sdate AND a.request_edate THEN 'Y' ELSE 'N' "
	+ " END) is_request "
	+ ", (CASE "
		+ " WHEN a.course_type = 'R' AND a.request_sdate > '" + m.time("yyyyMMdd") + "' THEN 'Y' ELSE 'N' "
	+ " END) is_prev "
	+ ", (CASE "
		+ " WHEN a.course_type = 'A' THEN 'Y' "
		+ " WHEN '" + m.time("yyyyMMdd") + "' BETWEEN a.study_sdate AND a.study_edate THEN 'Y' ELSE 'N' "
	+ " END) is_study "
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status NOT IN (-1, -4)) user_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.id AND status = 1) lesson_cnt "
	+ ", (SELECT COUNT(*) FROM " + coursePackage.table + " WHERE package_id = a.id) course_cnt "
	+ ", c.category_nm, c.parent_id "
	+ ", l.start_url sl_start_url, l.lesson_type sl_lesson_type "
	+ ", l.content_width sl_content_width, l.content_height sl_content_height "
	+ " FROM " + course.table + " a "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id AND c.module = 'course' AND c.status = 1 "
	+ " LEFT JOIN " + lesson.table + " l ON a.sample_lesson_id = l.id AND a.status = 1 "
	+ " WHERE a.id = " + id + " AND a.site_id = "+ siteId +" AND a.status = 1 "
	+ " AND (a.target_yn = 'N'" + (
			!"".equals(userGroups)
			? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = a.id AND group_id IN (" + userGroups + "))"
			: "")
	+ ") "
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata_or_permission")); return; }

info.put("course_nm_htt", m.htt(info.s("course_nm")));
info.put("request_block",
	(
		("Y".equals(info.s("is_request")) && "N".equals(info.s("limit_people_yn")))
		|| ("Y".equals(info.s("is_request")) && "Y".equals(info.s("limit_people_yn")) && info.i("limit_people") > info.i("user_cnt"))
	) && !info.b("close_yn") && info.b("sale_yn")
);

info.put("request_date", "-");
if("R".equals(info.s("course_type"))) {
	info.put("is_regular", true);
	info.put("request_date", m.time(_message.get("format.date.dot"), info.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), info.s("request_edate")));
	info.put("study_date", m.time(_message.get("format.date.dot"), info.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), info.s("study_edate")));
	info.put("ready_block", !"".equals(info.s("request_sdate")) ? 0 > m.diffDate("D", info.s("request_sdate"), m.time("yyyyMMdd")) : false);
} else if("A".equals(info.s("course_type"))) {
	info.put("is_regular", false);
	info.put("request_date", _message.get("list.course.types.A"));
	info.put("study_date", _message.get("list.course.types.A"));
	info.put("ready_block", false);
}

info.put("lesson_time", new DecimalFormat("#.##").format(info.d("lesson_time")));
info.put("lesson_time_conv", m.nf((int)info.d("lesson_time")));
info.put("lesson_time_hour", (int)Math.floor(info.d("lesson_time")));
info.put("lesson_time_min", (int)Math.round((info.d("lesson_time") - Math.floor(info.d("lesson_time"))) * 60));

if(!"".equals(info.s("course_file"))) {
	info.put("course_file_url", m.getUploadUrl(info.s("course_file")));
} else {
	info.put("course_file_url", "/html/images/common/noimage_course.gif");
}

info.put("limit_people_conv", "Y".equals(info.s("limit_people_yn")) ? m.nf(info.i("limit_people")) : "-");

info.put("price_conv", m.nf(info.i("price")));
info.put("list_price_conv", m.nf(info.i("list_price")));
info.put("list_price_block", info.i("list_price") > 0);

int discGroupPrice = info.i("price") - info.i("price") * userGroupDisc / 100; //CouponUserDao.getDiscountPrice() 와 맞춤
info.put("disc_group_price_block", info.b("disc_group_yn") && 0 < userGroupDisc);
info.put("disc_group_price", info.b("disc_group_price_block") ? discGroupPrice : info.i("price"));
info.put("disc_group_price_conv", m.nf(info.i("disc_group_price")));

//info.put("address", (!"".equals(info.s("address1")) || !"".equals(info.s("address2"))) ? info.s("address1") + " " + info.s("address2") : "-");
String[] courseAddr = m.split("|", info.s("course_address"));
info.put("course_addr", courseAddr[0]);
info.put("course_addr_dtl", (1 < courseAddr.length ? courseAddr[1] : ""));
info.put("course_address", m.replace(info.s("course_address"), "|", " ").trim());

//info.put("content1", m.nl2br(info.s("content1")));
info.put("content2", m.nl2br(info.s("content2")));

info.put("content_width_conv", info.i("content_width") + 20);
info.put("content_height_conv", info.i("content_height") + 23);

info.put("sl_content_width_conv", info.i("sl_content_width") + 20);
info.put("sl_content_height_conv", info.i("sl_content_height") + 23);

info.put("is_online", "N".equals(info.s("onoff_type")));
info.put("is_offline", "F".equals(info.s("onoff_type")));
info.put("is_blend", "B".equals(info.s("onoff_type")));
info.put("onoff_type_conv", m.getValue(info.s("onoff_type"), course.onoffPackageTypesMsg));

//수강생여부
info.put("course_user_id", courseUser.getCourseUserId(info.i("id"), userId, siteId));
info.put("course_user_block", 0 < info.i("course_user_id"));

int assignTotal = 0;
for(int i = 0; i < course.evaluationKeys.length; i++) assignTotal += info.i("assign_" + course.evaluationKeys[i]);
info.put("assign_total", assignTotal);

info.put("free_block", 0 == info.i("price"));
info.put("sample_lesson_block", info.i("sample_lesson_block") > 0);

//강사
DataSet tutors = courseTutor.query(
	"SELECT t.*, u.display_yn "
	+ " FROM " + courseTutor.table + " a "
	+ " LEFT JOIN " + tutor.table + " t ON a.user_id = t.user_id "
	+ " LEFT JOIN " + user.table + " u ON t.user_id = u.id "
	+ " WHERE a.course_id = " + id + " "
	+ " ORDER BY t.sort ASC, t.tutor_nm ASC "
);
while(tutors.next()) {
	tutors.put("tutor_file_url", m.getUploadUrl(tutors.s("tutor_file")));
}

//도서
info.put("book_price", 0);
DataSet books = courseBook.query(
	"SELECT a.*, b.* "
	+ " FROM " + courseBook.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
	+ " WHERE a.course_id = " + id + ""
);
while(books.next()) {
	if(!"".equals(books.s("book_img"))) books.put("book_img_url", m.getUploadUrl(books.s("book_img")));
	books.put("book_nm_conv", m.cutString(books.s("book_nm"), 20));
	books.put("book_price_conv", m.nf(books.i("book_price")));
	info.put("book_price", info.i("book_price") + books.i("book_price"));
}

//도서 구매 여부
info.put("book_buy_block", info.i("book_price") > 0 && info.i("price") > 0);
info.put("book_price_conv", m.nf(info.i("book_price")));

//차시
DataSet lessons = courseLesson.query(
	"SELECT a.*, l.onoff_type, l.lesson_nm, l.lesson_type, l.start_url, l.lesson_file, l.total_time, l.description "
	+ ", cs.id section_id, cs.section_nm "
	+ " FROM " + courseLesson.table + " a "
	+ " LEFT JOIN " + courseSection.table + " cs ON a.section_id = cs.id AND a.course_id = cs.course_id AND cs.status = 1 "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " WHERE a.status = 1 AND a.course_id = " + id + " "
	+ " ORDER BY a.chapter ASC"
);
int lastSectionId = 0;
while(lessons.next()) {
	lessons.put("start_date_conv", m.time(_message.get("format.date.hyphen"), lessons.s("start_date")));
	lessons.put("end_date_conv", m.time(_message.get("format.date.hyphen"), lessons.s("end_date")));

	lessons.put("onoff_type_conv", m.getValue(lessons.s("onoff_type"), lesson.onoffTypesMsg));
	lessons.put("description_conv", m.nl2br(lessons.s("description")));

	if(!"N".equals(info.s("onoff_type")) && "F".equals(lessons.s("onoff_type"))) {
		lessons.put("start_time", lessons.s("start_time").substring(0,2) + ":" + lessons.s("start_time").substring(2,4));
		lessons.put("end_time", lessons.s("end_time").substring(0,2) + ":" + lessons.s("end_time").substring(2,4));
	}

	if(lastSectionId != lessons.i("section_id") && 0 < lessons.i("section_id")) {
		lastSectionId = lessons.i("section_id");
		lessons.put("section_block", true);
	} else {
		lessons.put("section_block", false);
	}

}

//목록-시험
DataSet exams = courseModule.query(
	"SELECT a.*, e.exam_nm name "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + id + " AND e.site_id = " + siteId + ""
);
while(exams.next()) {
	exams.put("item_name", m.getValue(exams.s("item_type"), courseModule.examTypesMsg));
}

//목록-과제
DataSet homeworks = courseModule.query(
	"SELECT a.*, h.homework_nm name "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id AND h.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'homework' "
	+ " AND a.course_id = " + id + " AND h.site_id = " + siteId + ""
);
while(homeworks.next()) {
	homeworks.put("item_name", m.getValue(homeworks.s("item_type"), courseModule.homeworkTypesMsg));
}

//목록-토론
DataSet forums = courseModule.query(
	"SELECT a.*, f.forum_nm name "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + forum.table + " f ON a.module_id = f.id AND f.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'forum' "
	+ " AND a.course_id = " + id + " AND f.site_id = " + siteId + ""
);
while(forums.next()) {
	forums.put("item_name", m.getValue(forums.s("item_type"), courseModule.forumTypesMsg));
}

//목록-설문
DataSet surveys = courseModule.query(
	"SELECT a.*, s.survey_nm name "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module_id = s.id AND s.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'survey' "
	+ " AND a.course_id = " + id + " AND s.site_id = " + siteId + ""
);
while(surveys.next()) {
	surveys.put("item_name", m.getValue(surveys.s("item_type"), courseModule.surveyTypesMsg));
}


DataSet modules = courseModule.query(
	"SELECT a.module, COUNT(*) cnt, MAX(a.module_nm) module_nm "
	+ " FROM " + courseModule.table + " a "
	+ " WHERE a.status = 1 AND a.course_id = " + id + " "
	+ " GROUP BY a.module "
	+ " ORDER BY a.module ASC "
);
while(modules.next()) {
	if("exam".equals(modules.s("module"))) modules.put(".sub", exams);
	else if("homework".equals(modules.s("module"))) modules.put(".sub", homeworks);
	else if("forum".equals(modules.s("module"))) modules.put(".sub", forums);
	else if("survey".equals(modules.s("module"))) modules.put(".sub", surveys);

	modules.put("module_conv", m.getValue(modules.s("module"), courseModule.evaluationsMsg));
}

//패키지에포함된과정
DataSet courses = coursePackage.query(
	"SELECT a.*, c.* "
	+ " FROM " + coursePackage.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " AND c.onoff_type != 'P' AND c.status = 1 "
	+ " WHERE a.package_id = " + id + " "
	+ " ORDER BY a.sort ASC"
);
while(courses.next()) {
	courses.put("course_nm_conv", m.cutString(courses.s("course_nm"), 40));
	courses.put("course_type_conv", m.getValue(courses.s("course_type"), course.typesMsg));
	courses.put("onoff_type_conv", m.getValue(courses.s("onoff_type"), course.onoffPackageTypesMsg));
	if("R".equals(courses.s("course_type"))) {
		courses.put("request_date", m.time(_message.get("format.date.dot"), courses.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), courses.s("request_edate")));
		courses.put("study_date", m.time(_message.get("format.date.dot"), courses.s("study_sdate")) + " - " + m.time(_message.get("format.date.dot"), courses.s("study_edate")));
	} else if("A".equals(courses.s("course_type"))) {
		courses.put("request_date", _message.get("list.course.types.A"));
	}
}

//과정이포함된패키지
DataSet packages = coursePackage.query(
	"SELECT a.*, c.* "
	+ " FROM " + coursePackage.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.package_id = c.id AND c.site_id = " + siteId + " AND c.onoff_type = 'P' AND c.display_yn = 'Y' AND c.status = 1 "
	+ " WHERE a.course_id = " + id + " "
	+ " ORDER BY a.sort ASC"
);
while(packages.next()) {
	packages.put("course_nm_conv", m.cutString(packages.s("course_nm"), 40));
	packages.put("request_date", m.time(_message.get("format.date.dot"), packages.s("request_sdate")) + " - " + m.time(_message.get("format.date.dot"), packages.s("request_edate")));
}

//출력
p.setLayout(ch);
//if("P".equals(info.s("onoff_type"))) { p.setBody("course.package_view"); }
//else { p.setBody("course.course_view"); }
p.setBody("course.course_view");
p.setVar("p_title", info.s("course_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("tutors", tutors);
p.setLoop("books", books);

p.setLoop("lessons", lessons);
p.setLoop("modules", modules);

p.setLoop("courses", courses);
p.setLoop("packages", packages);

p.setVar("buy_block", info.i("price") > 0);
p.setVar("is_package", "P".equals(info.s("onoff_type")));

p.setVar("grade_title", Malgn.getItem(info.s("grade"), course.grades));
p.setVar("term_title", Malgn.getItem(info.s("term"), course.terms));
p.setVar("subject_title", Malgn.getItem(info.s("subject"), course.subjects));

p.setVar("section_colspan", 2 + (!"N".equals(info.s("onoff_type")) ? 1 : 0));
p.setVar("returl", m.urlencode(request.getRequestURI() + "?" + m.qs()));
p.display();

%>