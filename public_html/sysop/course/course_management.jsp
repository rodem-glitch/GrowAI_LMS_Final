<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseModuleDao courseModule = new CourseModuleDao();
LessonDao lesson = new LessonDao();

CourseBookDao courseBook = new CourseBookDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseTargetDao courseTarget = new CourseTargetDao();
CoursePrecedeDao coursePrecede = new CoursePrecedeDao();

BookDao book = new BookDao();
TutorDao tutor = new TutorDao();
GroupDao group = new GroupDao();

MCal mcal = new MCal(); mcal.yearRange = 10;

//카테고리
DataSet categories = category.getList(siteId);

//정보-과정
DataSet cinfo = course.query(
	"SELECT a.*"
	+ ", c.course_nm before_course_nm, l.lesson_nm sample_lesson_nm "
	+ " FROM " + course.table + " a "
	+ " LEFT JOIN " + course.table + " c ON a.before_course_id = c.id "
	+ " LEFT JOIN " + lesson.table + " l ON a.sample_lesson_id = l.id "
	+ " WHERE a.id = " + cid	+ " AND a.status != -1 AND a.site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND a.id IN (" + manageCourses + ") ": "")
);
if(!cinfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
cinfo.put("cate_name", category.getTreeNames(cinfo.i("category_id")));
cinfo.put("status_conv", m.getItem(cinfo.s("status"), course.statusList));
if("R".equals(cinfo.s("course_type"))) {
	cinfo.put("request_date", m.time("yyyy.MM.dd", cinfo.s("request_sdate")) + " - " + m.time("yyyy.MM.dd", cinfo.s("request_edate")));
	cinfo.put("study_date", m.time("yyyy.MM.dd", cinfo.s("study_sdate")) + " - " + m.time("yyyy.MM.dd", cinfo.s("study_edate")));
	cinfo.put("course_type_conv", "정규");
	cinfo.put("study_sdate_conv", m.time("yyyy-MM-dd", cinfo.s("study_sdate")));
	cinfo.put("study_edate_conv", m.time("yyyy-MM-dd", cinfo.s("study_edate")));
	cinfo.put("alltime_block", false);
} else if("A".equals(cinfo.s("course_type"))) {
	cinfo.put("request_date", "상시");
	cinfo.put("study_date", "상시");
	cinfo.put("course_type_conv", "상시");
	cinfo.put("alltime_block", true);
}
cinfo.put("period_conv", cinfo.b("period_yn") ? "학습기간 설정" : "-");
cinfo.put("lesson_order_conv", cinfo.b("lesson_order_yn") ? "순차학습" : "-");
cinfo.put("lesson_order_block", "N".equals(cinfo.s("onoff_type")));
cinfo.put("course_type_conv", m.getItem(cinfo.s("course_type"), course.types));
cinfo.put("onoff_type_conv", m.getItem(cinfo.s("onoff_type"), course.onoffTypes));
cinfo.put("online_block", "N".equals(cinfo.s("onoff_type")));
cinfo.put("display_conv", cinfo.b("display_yn") ? "정상" : "숨김");

//종료여부
boolean closed = cinfo.b("close_yn");


//폼체크
f.addElement("auto_approve_yn", cinfo.s("auto_approve_yn"), "hname:'신청즉시 승인여부'");
f.addElement("target_yn", cinfo.s("target_yn"), "hname:'학습대상자 사용여부', required:'Y'");
f.addElement("complete_auto_yn", cinfo.s("complete_auto_yn"), "hname:'자동 수료처리', required:'Y'");
f.addElement("restudy_yn", cinfo.s("restudy_yn"), "hname:'복습사용여부'");
f.addElement("restudy_day", cinfo.i("restudy_day"), "hname:'복습허용기간', option:'number'");

f.addElement("limit_lesson_yn", cinfo.s("limit_lesson_yn"), "hname:'학습강의제한 사용여부'");
f.addElement("limit_day", cinfo.i("limit_day"), "hname:'학습강의제한 일수', option:'number'");
f.addElement("limit_lesson", cinfo.i("limit_lesson"), "hname:'학습제한 강의 수', option:'number'");
f.addElement("limit_people_yn", cinfo.s("limit_people_yn"), "hname:'수강인원제한 사용유무'");
f.addElement("limit_people", cinfo.i("limit_people"), "hname:'수강제한인원', option:'number'");
f.addElement("period_yn", cinfo.s("period_yn"), "hname:'강의별 수강기간'");
f.addElement("lesson_order_yn", cinfo.s("lesson_order_yn"), "hname:'강의 순차적용 여부'");

f.addElement("exam_yn", cinfo.s("exam_yn"), "hname:'시험 사용여부'");
f.addElement("homework_yn", cinfo.s("homework_yn"), "hname:'과제 사용여부'");
f.addElement("forum_yn", cinfo.s("forum_yn"), "hname:'토론 사용여부'");
f.addElement("survey_yn", cinfo.s("survey_yn"), "hname:'설문 사용여부'");
f.addElement("review_yn", cinfo.s("review_yn"), "hname:'사용후기 사용여부'");
f.addElement("cert_course_yn", cinfo.s("cert_course_yn"), "hname:'수강증 사용여부'");
f.addElement("cert_complete_yn", cinfo.s("cert_complete_yn"), "hname:'수료증 사용여부'");
//새로 추가 Start
//f.addElement("cert_course2_yn", cinfo.s("cert_course2_yn"), "hname:'2학기 합격증 사용여부'");
//f.addElement("cert_complete2_yn", cinfo.s("cert_complete2_yn"), "hname:'2학기 수료증 사용여부'");
//f.addElement("status_fullcourse", cinfo.s("status_fullcourse"), "hname:'수료증합격증 4번사용여부'");
//새로 추가 End


f.addElement("sample_lesson_nm", cinfo.s("sample_lesson_nm"), "hname:'샘플동영상'");
f.addElement("before_course_nm", cinfo.s("before_course_nm"), "hname:'선행과정'");
f.addElement("course_address", cinfo.s("course_address"), "hname:'교육장소 주소'");

//등록
if(m.isPost() && f.validate()) {

	//제한
	if(closed) { m.jsAlert("해당 과정은 종료되어 수정할 수 없습니다."); return; }

	//course.item("recomm_yn", f.get("recomm_yn", "N"));

	course.item("auto_approve_yn", f.get("auto_approve_yn", "N"));
	course.item("target_yn", f.get("target_yn"));
	course.item("complete_auto_yn", f.get("complete_auto_yn"));
	course.item("restudy_yn", f.get("restudy_yn", "N"));
	course.item("restudy_day", "Y".equals(f.get("restudy_yn", "N")) ? f.getInt("restudy_day") : 0);

	course.item("limit_lesson_yn", f.get("limit_lesson_yn", "N"));
	course.item("limit_day", "Y".equals(f.get("limit_lesson_yn", "N")) ? f.getInt("limit_day") : 0);
	course.item("limit_lesson", "Y".equals(f.get("limit_lesson_yn", "N")) ? f.getInt("limit_lesson") : 0);
	course.item("limit_people_yn", f.get("limit_people_yn", "N"));
	course.item("limit_people", "Y".equals(f.get("limit_people_yn", "N")) ? f.getInt("limit_people") : 0);
	// course.item("period_yn", f.get("period_yn"));
	course.item("lesson_order_yn", f.get("lesson_order_yn"));

	course.item("sample_lesson_id", f.getInt("sample_lesson_id"));
	//course.item("before_course_id", f.getInt("before_course_id"));
	course.item("course_address", f.get("course_address"));

	course.item("exam_yn", f.get("exam_yn", "N"));
	course.item("homework_yn", f.get("homework_yn", "N"));
	course.item("forum_yn", f.get("forum_yn", "N"));
	course.item("survey_yn", f.get("survey_yn", "N"));
	course.item("review_yn", f.get("review_yn", "N"));
	course.item("cert_course_yn", f.get("cert_course_yn", "N"));
	course.item("cert_complete_yn", f.get("cert_complete_yn", "N"));
	//새로 추가 Start
		//course.item("cert_course2_yn", f.get("cert_course2_yn", "N"));
		//course.item("cert_complete2_yn", f.get("cert_complete2_yn", "N"));
		//course.item("status_fullcourse", f.get("status_fullcourse", "N"));
	//새로 추가 End

	if(!course.update("id = " + cid + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }


	//도서
	if(-1 != courseBook.execute("DELETE FROM " + courseBook.table + " WHERE course_id = " + cid + "")) {
		if(null != f.getArr("book_id")) {
			courseBook.item("course_id", cid);
			courseBook.item("site_id", siteId);
			for(int i = 0; i < f.getArr("book_id").length; i++) {
				courseBook.item("book_id", f.getArr("book_id")[i]);
				if(!courseBook.insert()) { }
			}
		}
	}


	//강사
	if(-1 != courseTutor.execute("DELETE FROM " + courseTutor.table + " WHERE course_id = " + cid + "")) {
		if(null != f.getArr("major_tutor_id")) {
			courseTutor.item("course_id", cid);
			courseTutor.item("site_id", siteId);
			courseTutor.item("type", "major");
			for(int i = 0; i < f.getArr("major_tutor_id").length; i++) {
				courseTutor.item("user_id", f.getArr("major_tutor_id")[i]);
				if(!courseTutor.insert()) { }
			}
		}
	}

	//그룹
	if(-1 != courseTarget.execute("DELETE FROM " + courseTarget.table + " WHERE course_id = " + cid + "")) {
		if(null != f.getArr("group_id")) {
			courseTarget.item("course_id", cid);
			courseTarget.item("site_id", siteId);
			for(int i = 0; i < f.getArr("group_id").length; i++) {
				courseTarget.item("group_id", f.getArr("group_id")[i]);
				if(!courseTarget.insert()) { }
			}
		}
	}

	//선행
	if(-1 != coursePrecede.execute("DELETE FROM " + coursePrecede.table + " WHERE course_id = " + cid + "")) {
		if(null != f.getArr("precede_id")) {
			coursePrecede.item("course_id", cid);
			coursePrecede.item("site_id", siteId);
			for(int i = 0; i < f.getArr("precede_id").length; i++) {
				coursePrecede.item("precede_id", f.getArr("precede_id")[i]);
				if(!coursePrecede.insert()) { }
			}
		}
	}

	m.jsAlert("수정하였습니다.");
	m.jsReplace("course_management.jsp?cid=" + cid, "parent");
	return;
}

//목록-도서
DataSet books = courseBook.query(
	"SELECT a.*, b.book_nm "
	+ " FROM " + courseBook.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
	+ " WHERE a.course_id = " + cid + ""
);

//목록-강사
DataSet tutors = courseTutor.query(
	"SELECT a.*, t.tutor_nm "
	+ " FROM " + courseTutor.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON t.user_id = a.user_id "
	+ " WHERE a.course_id = " + cid + ""
);

//목록-대상자
DataSet targets = courseTarget.query(
	"SELECT a.*, g.group_nm "
	+ " FROM " + courseTarget.table + " a "
	+ " INNER JOIN " + group.table + " g ON a.group_id = g.id AND g.site_id = " + siteId + " "
	+ " WHERE a.course_id = " + cid + ""
);

//목록-선행
DataSet pcourses = coursePrecede.query(
	"SELECT c.* "
	+ " FROM " + coursePrecede.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.precede_id = c.id "
	+ " WHERE a.course_id = " + cid + ""
);
while(pcourses.next()) {
	pcourses.put("course_nm_conv", m.cutString(pcourses.s("course_nm"), 40));
	pcourses.put("status_conv", m.getItem(pcourses.s("status"), course.statusList));
	pcourses.put("display_conv", pcourses.b("display_yn") ? "정상" : "숨김");
	pcourses.put("type_conv", m.getItem(pcourses.s("course_type"), course.types));
	pcourses.put("onoff_type_conv", m.getItem(pcourses.s("onoff_type"), course.onoffTypes));

	pcourses.put("alltimes_block", "A".equals(pcourses.s("course_type")));
	pcourses.put("request_sdate_conv", m.time("yyyy.MM.dd", pcourses.s("request_sdate")));
	pcourses.put("request_edate_conv", m.time("yyyy.MM.dd", pcourses.s("request_edate")));
	pcourses.put("study_sdate_conv", m.time("yyyy.MM.dd", pcourses.s("study_sdate")));
	pcourses.put("study_edate_conv", m.time("yyyy.MM.dd", pcourses.s("study_edate")));
}

//출력
p.setBody("course.course_management");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("status_list", m.arr2loop(course.statusList));

p.setVar("course", cinfo);

p.setLoop("books", books);
p.setLoop("tutors", tutors);
p.setLoop("targets", targets);
p.setLoop("pcourses", pcourses);

p.setVar("closed", closed);
p.display();

%>
