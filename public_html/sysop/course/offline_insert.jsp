<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(129, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseLessonDao courseLesson = new CourseLessonDao();
LessonDao lesson = new LessonDao();

MCal mcal = new MCal();

//변수
String userDeptNm = userDept.getOne("SELECT dept_nm FROM " + userDept.table + " WHERE id = " + userDeptId + " AND site_id = " + siteId + " AND status != -1");

//폼체크
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");
f.addElement("lesson_id", null, "hname:'교육과정', required:'Y'");
f.addElement("course_nm", "[" + userDeptNm + "] ", "hname:'과정 개설명', required:'Y'");
f.addElement("content1", null, "hname:'내용', allowhtml:'Y'");
f.addElement("study_date", m.time("yyyy-MM-dd"), "hname:'교육일'");
f.addElement("start_time_hour", null, "hname:'교육시작시간(시)'");
f.addElement("start_time_min", null, "hname:'교육시작시간(분)'");
f.addElement("end_time_hour", null, "hname:'교육종료시간(시)'");
f.addElement("end_time_min", null, "hname:'교육종료시간(분)'");
f.addElement("tutor_id", null, "hname:'강사', required:'Y', option:'number'");
f.addElement("lesson_time", 1, "hname:'시수', min:'0.25', required:'Y'");

//등록
if(m.isPost() && f.validate()) {
	//과정
	String studyDate = m.time("yyyyMMdd", f.get("study_date"));
	int newId = course.getSequence();
	course.item("id", newId);
	course.item("site_id", siteId);
	course.item("course_nm", f.get("course_nm"));
	course.item("category_id", f.getInt("category_id"));
	course.item("year", m.time("yyyy"));
	course.item("step", 1);

	course.item("onoff_type", "F");
	course.item("course_type", "R");

	course.item("request_sdate", studyDate);
	course.item("request_edate", studyDate);
	course.item("study_sdate", studyDate);
	course.item("study_edate", studyDate);

	course.item("lesson_day", 0);
	course.item("lesson_time", f.getDouble("lesson_time"));

	course.item("list_price", 0);
	course.item("price", 0);
	course.item("credit", 0);
	course.item("mobile_yn", "Y");
	course.item("evaluation_yn", "N");

	course.item("recomm_yn", "N");
	course.item("auto_approve_yn", "Y");
	course.item("sms_yn", "N");
	course.item("target_yn", "N");
	course.item("complete_auto_yn", "Y");
	course.item("restudy_yn", "N");
	course.item("restudy_day", 0);

	course.item("limit_lesson_yn", "N");
	course.item("limit_lesson", 0);
	course.item("limit_people_yn", "N");
	course.item("limit_people", 0);

	course.item("period_yn", "Y");
	course.item("lesson_order_yn", "N");

	course.item("assign_progress", 100);
	course.item("assign_exam", 0);
	course.item("assign_homework", 0);
	course.item("assign_forum", 0);
	course.item("assign_etc", 0);
	course.item("limit_progress", 60);
	course.item("limit_exam", 0);
	course.item("limit_homework", 0);
	course.item("limit_forum", 0);
	course.item("limit_etc", 0);
	course.item("limit_total_score", 60);
	course.item("class_member", 40); //고정

	course.item("sample_lesson_id", 0);
	course.item("before_course_id", 0);

	course.item("subtitle", "");
	course.item("content1_title", "");
	course.item("content1", "");
	course.item("content2_title", "");
	course.item("content2", "");

	course.item("manager_id", userId);
	course.item("exam_yn", "N");
	course.item("homework_yn", "N");
	course.item("forum_yn", "N");
	course.item("survey_yn", "N");
	course.item("review_yn", "N");
	course.item("cert_course_yn", "Y");
	course.item("cert_complete_yn", "Y");

	// 합격증/수료증 템플릿 기능을 사용하지 않는 기본 과정이므로
	// 관련 컬럼을 기본값으로 세팅해 NOT NULL 환경에서도 오류를 방지합니다.
	course.item("cert_template_id", 0);
	course.item("pass_yn", "N");
	course.item("pass_cert_template_id", 0);

	course.item("etc1", "");
	course.item("etc2", "");

	course.item("display_yn", "N");
	course.item("sale_yn", "N");
	course.item("reg_date", m.time("yyyyMMddHHmmss"));
	course.item("status", 1);

	if(!course.insert()) { m.jsAlert("과정을 등록하는 중 오류가 발생했습니다."); return; }

	//과정게시판
	ClBoardDao board = new ClBoardDao(siteId);
	if(!board.insertBoard(newId)) { }

	//강사
	courseTutor.item("course_id", newId);
	courseTutor.item("site_id", siteId);
	courseTutor.item("user_id", f.getInt("tutor_id"));
	courseTutor.item("type", "major");
	if(!courseTutor.insert()) { m.jsAlert("강사를 등록하는 중 오류가 발생했습니다."); return; }
	
	//강의
	courseLesson.item("course_id", newId);
	courseLesson.item("lesson_id", f.getInt("lesson_id"));
	courseLesson.item("site_id", siteId);
	courseLesson.item("chapter", 1);
	courseLesson.item("start_day", 0);
	courseLesson.item("period", 0);
	courseLesson.item("start_date", studyDate);
	courseLesson.item("end_date", studyDate);
	courseLesson.item("start_time", f.get("start_time_hour") + f.get("start_time_min") + "00");
	courseLesson.item("end_time", f.get("end_time_hour") + f.get("end_time_min") + "00");
	courseLesson.item("lesson_hour", f.getDouble("lesson_time"));
	courseLesson.item("tutor_id", f.getInt("tutor_id"));
	courseLesson.item("progress_yn", "Y");
	courseLesson.item("status", 1);
	if(!courseLesson.insert()) { m.jsAlert("강의를 등록하는 중 오류가 발생했습니다."); return; }

	m.jsAlert("성공적으로 등록했습니다.");
	m.js("parent.OpenWindows('user_add.jsp?cid=' + " + newId + ", '_CUA1', 900, 700);");
	m.jsReplace("../course/user_list.jsp?s_course_id=" + newId, "parent");
	return;
}

//목록-강사
DataSet tutors = user.find("site_id = " + siteId + " AND tutor_yn = 'Y' AND status = 1");
while(tutors.next()) {
	if(0 < tutors.i("dept_id")) {
		tutors.put("dept_nm_conv", userDept.getNames(tutors.i("dept_id")));
	} else {
		tutors.put("dept_nm", "[미소속]");
		tutors.put("dept_nm_conv", "[미소속]");
	}
	user.maskInfo(tutors);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && tutors.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, tutors.size(), "이러닝 운영", tutors);

//출력
p.setBody("course.offline_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("tutors", tutors);
p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes(5));
p.display();

%>
