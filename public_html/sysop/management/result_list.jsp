<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
LessonDao lesson = new LessonDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
SurveyDao survey = new SurveyDao();
SurveyUserDao surveyUser = new SurveyUserDao();

//변수
String today = m.time("yyyyMMdd");

//폼체크
f.addElement("s_close_yn", null, null);
f.addElement("s_complete_yn", null, null);

f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

f.addElement("s_listnum", null, null);

if(m.isPost() && "save".equals(m.rs("mode"))) {

	//기본키
	int cuid = m.ri("cuid");
	int uid = m.ri("uid");
	if(cuid == 0 || uid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	DataSet cuinfo = courseUser.query(
		"SELECT a.*, b.assign_progress, b.assign_exam, b.assign_homework, b.assign_forum, b.assign_etc, u.login_id, u.user_nm "
		+ " FROM " + courseUser.table + " a "
		+ " INNER JOIN " + course.table + " b ON a.course_id = b.id "
		+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE a.id = " + cuid + " AND a.course_id = "+ courseId + " AND a.user_id = " + uid + " AND a.status IN (1,3)"
	);
	if(!cuinfo.next()) { m.jsError("해당 수강생정보가 없습니다."); return; }

	/*
	courseUser.item("progress_score", Math.min(cuinfo.d("assign_progress"), m.parseDouble(m.rs("progress_score"))));
	courseUser.item("exam_score", Math.min(cuinfo.d("assign_exam"), m.parseDouble(m.rs("exam_score"))));
	courseUser.item("homework_score", Math.min(cuinfo.d("assign_homework"), m.parseDouble(m.rs("homework_score"))));
	courseUser.item("forum_score", Math.min(cuinfo.d("assign_forum"), m.parseDouble(m.rs("forum_score"))));
	*/
	double etcValue = m.round(m.parseDouble(m.rs("etc_score")) * 100 / cinfo.i("assign_etc"), 2);
	double etcScore = Math.min(cuinfo.d("assign_etc"), m.parseDouble(m.rs("etc_score")));
	courseUser.item("etc_value", etcValue);
	courseUser.item("etc_score", etcScore);
	if(!courseUser.update("id = " + cuid + " AND course_id = " + courseId + " AND user_id = " + uid + "")) {
		m.js("parent.LayerAlert('" + cuinfo.s("user_nm") + " (" + cuinfo.s("login_id") + ") 수강생의 기타점수를 저장하는 중 오류가 발생했습니다.', 'red');");
	} else {
		m.js("parent.LayerAlert('" + cuid + "번 " + cuinfo.s("user_nm") + " (" + cuinfo.s("login_id") + ") 수강생의 기타점수를 " + String.format("%.2f", etcScore) + "점으로 저장했습니다.', 'green'); parent.document.getElementById('etc_score_" + cuinfo.i("id") + "').value = '" + String.format("%.2f", etcScore) + "';");
	}

	courseUser.updateTotalScore(cuid);
	//m.jsAlert("저장되었습니다.");
	//m.jsReplace("result_list.jsp?" + m.qs("id,mode,cuid"), "parent");
	return;
} else if(m.isPost() && "update".equals(m.rs("mode"))) {

	//기본키
	int cuid = m.ri("cuid");
	int uid = m.ri("uid");
	if(cuid == 0 || uid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//수강생정보
	DataSet cuinfo = courseUser.query(
		" SELECT a.* "
		+ " FROM " + courseUser.table + " a "
		+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE a.id = " + cuid + " AND a.course_id = " + courseId + " AND a.user_id = " + uid + " AND a.status IN (1,3) "
	);
	if(!cuinfo.next()) { m.jsAlert("해당 수강생정보가 없습니다."); return; }

	//성적처리
	cuinfo.first();
	cinfo.first();
	if(!courseUser.updateUserScore(cuinfo, cinfo)) { m.jsAlert("성적을 처리하는 중 오류가 발생했습니다."); return; }
	m.jsAlert("처리되었습니다.");
	m.jsReplace("result_list.jsp?" + m.qs("id,mode,cuid"), "parent");
	return;

} else if(m.isPost() && "updateall".equals(m.rs("mode"))) {
	//성적처리
	int result = 0;
	DataSet cuinfo = courseUser.query(
		" SELECT a.* "
		+ " FROM " + courseUser.table + " a "
		+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE a.course_id = " + courseId + " AND a.status IN (1,3) "
	);
	while(cuinfo.next()) {
		DataSet temp = new DataSet();
		temp.addRow();
		temp.put("id", cuinfo.i("id"));
		temp.put("etc_score", cuinfo.d("etc_score"));
		temp.first();
		cinfo.first();

		if(courseUser.updateUserScore(temp, cinfo)) result++;
	}
	m.jsAlert(result + "건이 처리되었습니다.");
	m.jsReplace("result_list.jsp?" + m.qs("id,mode,cuid"), "parent");
	return;
	
} else if(m.isPost() && "ratioall".equals(m.rs("mode"))) {
	//진도율재산정
	//차시정보
	DataSet cllist = courseLesson.query(
		" SELECT a.*, l.lesson_type, l.total_time, l.complete_time, l.total_page "
		+ " FROM " + courseLesson.table + " a "
		+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
		+ " WHERE a.course_id = " + courseId + " AND a.status = 1 "
	);
	while(cllist.next()) {
		cllist.put("total_time", cllist.i("total_time") * 60);
		cllist.put("complete_time", cllist.i("complete_time") * 60);
	}
	//처리
	int success = 0;
	DataSet culist = courseUser.query(
		" SELECT a.* "
		+ " FROM " + courseUser.table + " a "
		+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
		+ " WHERE a.course_id = " + courseId + " AND a.status IN (1,3) "
	);
	while(culist.next()) success += courseProgress.reupdateProgress(culist, cllist);

	m.jsAlert(success + "건이 처리되었습니다.");
	m.jsReplace("result_list.jsp?" + m.qs("id,mode"), "parent");
	return;
}

//정보-설문수
int totalSurveyCnt = courseModule.getOneInt(
	" SELECT COUNT(*) FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module = 'survey' AND a.module_id = s.id AND s.status = 1 "
	+ " WHERE a.course_id = " + courseId + " AND a.site_id = " + siteId + " AND a.status = 1 "
);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
	courseUser.table + " a "
	+ " INNER JOIN " + course.table + " b ON b.id = a.course_id AND b.site_id = " + siteId + " "
	+ " INNER JOIN " + user.table + " d ON a.user_id = d.id "
);
lm.setFields(
	"a.*, b.course_nm, b.year, b.step "
	+ ", b.assign_progress, b.assign_exam, b.assign_homework, b.assign_forum, b.assign_etc"
	+ ", b.limit_progress, b.limit_exam, b.limit_homework, b.limit_forum, b.limit_etc"
	+ ", d.user_nm, d.login_id "
	+ ", (SELECT COUNT(*) FROM " + surveyUser.table + " WHERE course_user_id = a.id AND status = 1) survey_cnt "
);
lm.addWhere("a.status IN(1, 3)");
lm.addWhere("a.course_id = " + courseId + "");
if(deptManagerBlock) lm.addWhere("d.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")");
lm.addSearch("a.close_yn", f.get("s_close_yn"));
lm.addSearch("a.complete_yn", f.get("s_complete_yn"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("d.user_nm,b.course_nm,d.login_id", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "b.year DESC, b.step DESC, b.course_nm, b.reg_date DESC, a.id DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	String status = "-";
	if(list.b("close_yn")) status = "마감";
	else if(!"".equals(list.s("complete_yn")) && list.b("complete_yn")) status = "수료";
	else if(!"".equals(list.s("complete_yn")) && !list.b("complete_yn")) status = "미수료";
	else if("".equals(list.s("complete_yn"))) {
		if(0 > m.diffDate("D", list.s("start_date"), today)) status = "대기중";
		else if(0 < m.diffDate("D", list.s("end_date"), today)) status = "학습종료";
		else status = "학습중";
	}
	list.put("status_conv", status);

	list.put("progress_block", list.d("progress_score") > 0.0);
	list.put("exam_block", list.d("exam_score") > 0.0);
	list.put("homework_block", list.d("homework_score") > 0.0);
	list.put("forum_block", list.d("forum_score") > 0.0);
	list.put("survey_block", list.i("survey_cnt") > 0);
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), inquiryPurpose, list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), inquiryPurpose, list);

	ExcelWriter ex = new ExcelWriter(response, "수강생성적관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "course_id=>과정코드", "course_nm=>과정명", "year=>년도", "step=>기수", "user_nm=>회원명", "user_id=>회원아이디", "login_id=>로그인아이디", "status_conv=>상태", "total_score=>총점", "progress_ratio=>진도율", "progress_score=>진도점수", "exam_score=>평가점수", "homework_score=>과제점수", "etc_score=>기타점수", "survey_cnt=>참여설문수" }, "수강생성적관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("management.result_list");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs("mode, tid, sp"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("tab_query", m.qs("ord, mode, tid, sp"));
p.setVar("list_query", m.qs("id, mode, tid, sp"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("total_survey_cnt", totalSurveyCnt);
p.display();

%>