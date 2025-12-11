<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseUserDao courseUser = new CourseUserDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseLibraryDao courseLibrary = new CourseLibraryDao();
ClBoardDao board = new ClBoardDao();
MCal mcal = new MCal(); mcal.yearRange = 10;

//폼체크
f.addElement("s_req_sdate", null, null);
f.addElement("s_req_edate", null, null);
f.addElement("s_std_sdate", null, null);
f.addElement("s_std_edate", null, null);

f.addElement("s_year", null, null);
f.addElement("s_category", null, null);
f.addElement("s_type", null, null);
f.addElement("s_progress", null, null);
f.addElement("s_status", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//카테고리
DataSet categories = category.getList(siteId);

//변수
String today = m.time("yyyyMMdd");

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 1000000 : f.getInt("s_listnum", 20));
lm.setTable(course.table + " a");
lm.setFields("a.*"
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status IN (0,1,3)) total_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseUser.table + " cu "
		+ " INNER JOIN " + user.table + " u ON cu.user_id = u.id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE cu.course_id = a.id AND cu.status IN (1,3) "
	+ " ) user_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.id AND status != -1) lesson_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseModule.table + " WHERE course_id = a.id AND module = 'exam') exam_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseModule.table + " WHERE course_id = a.id AND module = 'homework') homework_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseModule.table + " WHERE course_id = a.id AND module = 'forum') forum_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseModule.table + " WHERE course_id = a.id AND module = 'survey') survey_cnt "
	+ ", (SELECT COUNT(*) FROM " + courseLibrary.table + " WHERE course_id = a.id) library_cnt "
	+ ", (SELECT COUNT(*) FROM " + board.table + " WHERE course_id = a.id AND status = 1) board_cnt "
);
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.addWhere("a.onoff_type != 'P'");
lm.addSearch("a.year", f.get("s_year"));
lm.addSearch("a.course_type", f.get("s_type"));
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.onoff_type", f.get("s_onofftype"));
if("C".equals(userKind)) lm.addWhere("a.id IN (" + manageCourses + ")");
if(!"".equals(f.get("s_req_sdate"))) lm.addWhere("a.request_edate >= '" + m.time("yyyyMMdd", f.get("s_req_sdate")) + "'");
if(!"".equals(f.get("s_req_edate"))) lm.addWhere("a.request_sdate <= '" + m.time("yyyyMMdd", f.get("s_req_edate")) + "'");
if(!"".equals(f.get("s_std_sdate"))) lm.addWhere("a.study_edate >= '" + m.time("yyyyMMdd", f.get("s_std_sdate")) + "'");
if(!"".equals(f.get("s_std_edate"))) lm.addWhere("a.study_sdate <= '" + m.time("yyyyMMdd", f.get("s_std_edate")) + "'");
if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
}
if(f.getInt("s_progress") == 1)	lm.addWhere("a.course_type != 'A' AND a.request_sdate > '" + today + "'");
else if(f.getInt("s_progress") == 2) lm.addWhere("a.course_type != 'A' AND (a.request_sdate <= '" + today + "' AND a.request_edate >= '"+ today +"')");
else if(f.getInt("s_progress") == 3) lm.addWhere("(a.course_type = 'A' OR (a.study_sdate <= '" + today + "' AND a.study_edate >= '"+ today +"'))");
else if(f.getInt("s_progress") == 4) lm.addWhere("a.course_type != 'A' AND a.study_edate < '" + today + "'");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.course_nm, a.etc1, a.etc2", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC, a.id DESC");


//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("course_nm_conv", m.cutString(list.s("course_nm"), 50));

	if(list.b("close_yn")) list.put("progress_conv", "마감");
	else if("A".equals(list.s("course_type"))) list.put("progress_conv", "학습");
	else if(8 == list.s("request_sdate").length() && 0 < m.diffDate("D", today, list.s("request_sdate"))) list.put("progress_conv", "대기");
	else if(8 == list.s("study_edate").length() && 0 > m.diffDate("D", today, list.s("study_edate"))) list.put("progress_conv", "종료");
	else if(8 == list.s("study_sdate").length() && 8 == list.s("study_edate").length() && 0 >= m.diffDate("D", today, list.s("study_sdate")) && 0 <= m.diffDate("D", today, list.s("study_edate"))) list.put("progress_conv", "학습");
	else if(8 == list.s("request_sdate").length() && 8 == list.s("request_edate").length() && 0 >= m.diffDate("D", today, list.s("request_sdate")) && 0 <= m.diffDate("D", today, list.s("request_edate"))) list.put("progress_conv", "신청");
	else list.put("progress_conv", "-");

	list.put("type_conv", m.getItem(list.s("course_type"), course.types));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), course.onoffTypes));

	list.put("alltimes_block", "A".equals(list.s("course_type")));
	list.put("request_sdate_conv", m.time("yyyy.MM.dd", list.s("request_sdate")));
	list.put("request_edate_conv", m.time("yyyy.MM.dd", list.s("request_edate")));
	list.put("study_sdate_conv", m.time("yyyy.MM.dd", list.s("study_sdate")));
	list.put("study_edate_conv", m.time("yyyy.MM.dd", list.s("study_edate")));

	list.put("user_cnt_conv", m.nf(list.i("user_cnt")));
	list.put("lesson_cnt_conv", m.nf(list.i("lesson_cnt")));

	list.put("price_conv", m.nf(list.i("price")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("course_file_url", !"".equals(list.s("course_file")) ? siteDomain + m.getUploadUrl(list.s("course_file")) : "");
	list.put("cate_name", category.getTreeNames(list.i("category_id")));

	list.put("attend_block", !"N".equals(list.s("onoff_type")));
	
	list.put("tutor_nm_conv", courseTutor.getTutorName(list.i("id")));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "과정운영(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "id=>과정아이디", "onoff_type_conv=>구분", "course_nm=>과정명", "cate_name=>카테고리", "tutor_nm_conv=>강사", "lesson_day=>상시수강일수", "request_sdate_conv=>정규신청시작일", "request_edate_conv=>정규신청종료일", "study_sdate_conv=>정규학습시작일", "study_edate_conv=>정규학습종료일", "lesson_time=>시수", "list_price=>정가", "price=>수강료(실결제가)", "credit=>학점", "user_cnt=>수강생 수", "lesson_cnt=>차시 수", "exam_cnt=>시험 수", "homework_cnt=>과제 수", "forum_cnt=>토론 수", "survey_cnt=>설문 수", "library_cnt=>자료 수", "assign_progress=>출석(진도) 배점", "assign_exam=>평가 배점", "assign_homework=>과제 배점", "assign_forum=>토론 배점", "assign_etc=>기타 배점", "limit_progress=>출석(진도) 수료기준", "limit_exam=>평가 수료기준", "limit_homework=>과제 수료기준", "limit_forum=>토론 수료기준", "limit_etc=>기타 수료기준", "limit_total_score=>총점 수료기준", "reg_date_conv=>등록일", "progress_conv=>진행상태"}, "과정운영(" + m.time("yyyy-MM-dd") +")");
	ex.write();
	return;
}

//출력
p.setBody("management.course_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(course.statusList));
p.setLoop("categories", categories);
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("onoff_types", m.arr2loop(course.onoffTypes));
p.setLoop("years", mcal.getYears());
p.setVar("this_year", m.time("yyyy"));
p.display();

%>