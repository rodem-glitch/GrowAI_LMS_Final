<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
if(!adminBlock) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
String idx = m.rs("idx");
if("".equals(idx)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseSectionDao courseSection = new CourseSectionDao();

MCal mcal = new MCal(); mcal.yearRange = 10;

//변수
boolean isRegular = false;
boolean isAlltime = false;

//목록-과정
DataSet list = course.find("id IN (" + idx + ") AND site_id = " + siteId + " AND onoff_type != 'P' AND status != -1");
if(1 > list.size()) { m.jsError("해당 과정 정보가 없습니다."); return; }

while(list.next()) {
	if("R".equals(list.s("course_type"))) isRegular = true;
	if("A".equals(list.s("course_type"))) isAlltime = true;
}

//폼체크
if(isRegular) {
	f.addElement("request_sdate", null, "hname:'수강신청시작일', required:'Y'");
	f.addElement("request_edate", null, "hname:'수강신청종료일', required:'Y'");
	f.addElement("study_sdate", null, "hname:'학습시작일', required:'Y'");
	f.addElement("study_edate", null, "hname:'학습종료일', required:'Y'");
}
if(isAlltime) {
	f.addElement("lesson_day", null, "hname:'수강일', required:'Y', min:'1'");
}

//변수
int thisYear = m.parseInt(m.time("yyyy"));

//등록
if(m.isPost() && f.validate()) {
	//객체
	CourseBookDao book = new CourseBookDao();
	CourseLessonDao lesson = new CourseLessonDao();
	CourseLibraryDao library = new CourseLibraryDao();
	CourseModuleDao module = new CourseModuleDao();
	CoursePrecedeDao precede = new CoursePrecedeDao();
	CourseTargetDao target = new CourseTargetDao();
	CourseTutorDao tutor = new CourseTutorDao();
	ClBoardDao board = new ClBoardDao(siteId);

	//변수
	DataSet clist = f.getArrList(new String[] {"course_id", "year", "step", "course_nm"});
	int size = clist.size();
	int success = 0;

	course.setCopyDate(
		m.time("yyyyMMdd", f.get("request_sdate")), m.time("yyyyMMdd", f.get("request_edate"))
		, m.time("yyyyMMdd", f.get("study_sdate")), m.time("yyyyMMdd", f.get("study_edate"))
		, f.getInt("lesson_day")
	);
	
	//복사
	while(clist.next()) {
		//과정
		int courseId = clist.i("course_id");
		int newId = course.copyCourse(courseId, clist.i("year"), clist.i("step"), clist.s("course_nm"));
		if(0 > newId) continue;

		//과정게시판
		if(!board.insertBoard(newId)) continue;

		//연계테이블
		if(course.copyDetail(new DataObject[] {book, lesson, library, module, precede, target, tutor}, courseId, newId)) {
			if(courseSection.copySection(courseId, newId)) success++;
		}

		//차시별수강기간보정
		DataSet cllist = lesson.find("course_id = " + newId);
		while(cllist.next()) {
			lesson.clear();
			if(!"".equals(cllist.s("start_date")) || !"".equals(cllist.s("end_date"))) {
				lesson.item("start_date", m.time("yyyyMMdd", f.get("study_sdate")));
				lesson.item("end_date", m.time("yyyyMMdd", f.get("study_edate")));
				lesson.update("course_id = " + newId + " AND lesson_id = " + cllist.s("lesson_id"));
			}
		}
	}

	m.jsAlert("총 " + size + "과목 중 " + success + "과목을 복사했습니다.");
	m.jsReplace("course_list.jsp?" + m.qs("idx"), "parent");
	return;
}

//포멧팅
list.first();
while(list.next()) {
	list.put("year_conv", list.i("year") < thisYear ? thisYear : list.i("year"));
	list.put("step_conv", list.i("year") < thisYear ? 1 : list.i("step") + 1);

	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffPackageTypes));

	list.put("package_block", "P".equals(list.s("onoff_type")));
	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));
	
	list.put("ROW_CLASS", list.i("__ord") % 2 != 0 ? "even" : "odd");
}

//출력
p.setLayout("poplayer");
p.setBody("course.course_copy");
p.setVar("p_title", "과정 복사");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);

p.setLoop("status_list", m.arr2loop(course.statusList));
p.setLoop("onoff_types", m.arr2loop(course.onoffPackageTypes));
p.setLoop("years", mcal.getYears());
p.setVar("regular_block", isRegular);
p.setVar("alltime_block", isAlltime);
p.display();

%>