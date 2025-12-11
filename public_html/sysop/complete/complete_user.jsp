<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(76, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
LmCategoryDao category = new LmCategoryDao("course");
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseModuleDao courseModule = new CourseModuleDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
SurveyDao survey = new SurveyDao();
SurveyUserDao surveyUser = new SurveyUserDao();

//카테고리
DataSet categories = category.getList(siteId);

//정보-과정
DataSet cinfo = course.find(
	"id = " + cid + " AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
cinfo.put("cate_name", category.getTreeNames(cinfo.i("category_id")));
cinfo.put("status_conv", m.getItem(cinfo.s("status"), course.statusList));
cinfo.put("close_date_conv", m.time("yyyy-MM-dd HH:mm", cinfo.s("close_date")));

cinfo.put("std_progress", m.nf(cinfo.i("assign_progress") * cinfo.i("limit_progress") / 100, 2));
cinfo.put("std_exam", m.nf(cinfo.i("assign_exam") * cinfo.i("limit_exam") / 100, 2));
cinfo.put("std_homework", m.nf(cinfo.i("assign_homework") * cinfo.i("limit_homework") / 100, 2));
cinfo.put("std_forum", m.nf(cinfo.i("assign_forum") * cinfo.i("limit_forum") / 100, 2));
cinfo.put("std_etc", m.nf(cinfo.i("assign_etc") * cinfo.i("limit_etc") / 100, 2));
cinfo.put("display_conv", cinfo.b("display_yn") ? "정상" : "숨김");

//처리
if("complete_y".equals(m.rs("mode"))) {
	String idx = m.rs("idx");
	if("".equals(idx)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	DataSet culist = courseUser.find("status IN (1,3) AND close_yn = 'N' AND id IN ( " + idx + " )");
	while(culist.next()) courseUser.completeUser(culist.i("id"));

	m.jsAlert(m.nf(culist.size()) + "명이 수료처리 되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid, "parent");
	return;
} else if("all_complete_y".equals(m.rs("mode"))) {
	DataSet culist = courseUser.find("status IN (1,3) AND course_id = " + cid + " AND close_yn = 'N'", "*, progress_ratio progress_value");
	while(culist.next()) {
		courseUser.completeUser(culist.i("id"));
	}

	m.jsAlert(m.nf(culist.size()) + "명이 수료처리 되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid, "parent");
	return;
} else if("complete_n".equals(m.rs("mode"))) {
	String idx = m.rs("idx");
	if("".equals(idx)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	int cuCnt = courseUser.findCount("status IN (1,3) AND close_yn = 'N' AND id IN ( " + idx + ")");
	courseUser.item("complete_yn", "");
	courseUser.item("complete_status", "");
	courseUser.item("complete_no", "");
	courseUser.item("complete_date", "");
	courseUser.item("fail_reason", "");
	courseUser.item("mod_date", sysNow);
	if(!courseUser.update("status IN (1,3) AND close_yn = 'N' AND id IN (" + idx + ")")) {
		m.jsAlert("수료를 취소하는 중 오류가 발생했습니다."); return;
	}

	m.jsAlert(m.nf(cuCnt) + "명이 수료취소 되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid, "parent");
	return;
} else if("all_complete_n".equals(m.rs("mode"))) {

	int cuCnt = courseUser.findCount("status IN (1,3) AND course_id = " + cid + " AND close_yn = 'N'");
	courseUser.item("complete_yn", "");
	courseUser.item("complete_status", "");
	courseUser.item("complete_no", "");
	courseUser.item("complete_date", "");
	courseUser.item("fail_reason", "");
	courseUser.item("mod_date", sysNow);
	if(!courseUser.update("status IN (1,3) AND course_id = " + cid + " AND close_yn = 'N'")) {
		m.jsAlert("수료를 취소하는 중 오류가 발생했습니다."); return;
	}

	m.jsAlert(m.nf(cuCnt) + "명이 수료취소 되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid, "parent");
	return;

} else if("close_y".equals(m.rs("mode"))) {
	String idx = m.rs("idx");
	if("".equals(idx)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	DataSet culist = courseUser.find("status IN (1,3) AND close_yn = 'N' AND id IN ( " + idx + " )");
	while(culist.next()) {
		if("".equals(culist.s("complete_yn"))) courseUser.completeUser(culist.i("id"));

		courseUser.item("close_yn", "Y");
		courseUser.item("close_date", sysNow);
		courseUser.item("close_user_id", userId);
		courseUser.item("mod_date", sysNow);
		if(!courseUser.update("id = " + culist.i("id") + "")) { }
	}

	m.jsAlert(m.nf(culist.size()) + "명이 종료처리 되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid, "parent");
	return;
} else if("all_close_y".equals(m.rs("mode"))) {

	DataSet culist = courseUser.find("status IN (1,3) AND course_id = " + cid + " AND close_yn = 'N'", "*, progress_ratio progress_value");
	while(culist.next()) {
		if("".equals(culist.s("complete_yn"))) courseUser.completeUser(culist.i("id"));

		courseUser.item("close_yn", "Y");
		courseUser.item("close_date", sysNow);
		courseUser.item("close_user_id", userId);
		courseUser.item("mod_date", sysNow);
		if(!courseUser.update("id = " + culist.i("id") + "")) { }
	}

	m.jsAlert(m.nf(culist.size()) + "명이 종료처리 되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid, "parent");
	return;
} else if("close_n".equals(m.rs("mode"))) {
	String idx = m.rs("idx");
	if("".equals(idx)) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

	int cuCnt = courseUser.findCount("status IN (1,3) AND close_yn = 'Y' AND id IN ( " + idx + " )");
	courseUser.item("close_yn", "N");
	courseUser.item("close_date", "");
	courseUser.item("close_user_id", 0);
	courseUser.item("mod_date", sysNow);
	if(!courseUser.update("status IN (1,3) AND close_yn = 'Y' AND id IN ( " + idx + " )")) {
		m.jsAlert("종료를 취소하는 중 오류가 발생했습니다."); return;
	}

	m.jsAlert(m.nf(cuCnt) + "명이 종료취소 되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid, "parent");
	return;
} else if("all_close_n".equals(m.rs("mode"))) {

	int cuCnt = courseUser.findCount("status IN (1,3) AND course_id = " + cid + " AND close_yn = 'Y'");
	courseUser.item("close_yn", "N");
	courseUser.item("close_date", "");
	courseUser.item("close_user_id", 0);
	courseUser.item("mod_date", sysNow);
	if(!courseUser.update("status IN (1,3) AND course_id = " + cid + " AND close_yn = 'Y'")) {
		m.jsAlert("종료를 취소하는 중 오류가 발생했습니다."); return;
	}

	m.jsAlert(m.nf(cuCnt) + "명이 종료취소 되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid, "parent");
	return;
} else if("reset_compno".equals(m.rs("mode"))) {
	DataSet culist = courseUser.find("status IN (1,3) AND course_id = " + cid + " AND site_id = " + siteId, "*", " id desc ");

	String now = m.time("yyyyMMddHHmmss");

	while(culist.next()) {
		courseUser.clear();

		String completeDate = culist.s("end_date") + "235959";
		if("A".equals(cinfo.s("course_type")) && 0 < m.diffDate("D", now, completeDate)) completeDate = now;
		courseUser.item("complete_no", m.time("yyyy", completeDate) + "-" + culist.i("id"));

		if(!courseUser.update(" id = " + culist.i("id") + "")) {  return; }
	}

	m.jsAlert("수료번호 재부여가 완료되었습니다.");
	m.jsReplace("complete_user.jsp?cid=" + cid);
	return;
}

//정보-설문수
int totalSurveyCnt = courseModule.getOneInt(
	" SELECT COUNT(*) FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module_id = s.id AND s.status = 1 "
	+ " WHERE a.module = 'survey' AND a.course_id = " + cid + " AND a.site_id = " + siteId + " AND a.status = 1 "
);

//폼체크
f.addElement("s_complete", null, null);
f.addElement("s_complete_status", null, null);
f.addElement("s_close", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode2")) ? 20000 : f.getInt("s_listnum", 20));
lm.setTable(
	courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
);
lm.setFields(
	" a.*, u.user_nm, u.login_id "
	+ ", (SELECT COUNT(*) FROM " + surveyUser.table + " WHERE course_user_id = a.id AND status = 1) survey_cnt "
);
lm.addWhere("a.status IN(1, 3)");
lm.addWhere("a.course_id = " + cid + "");
if("none".equals(f.get("s_complete"))) lm.addWhere("(a.complete_yn = '' OR a.complete_yn IS NULL)");
else lm.addSearch("a.complete_yn", f.get("s_complete"));
if(!"".equals(f.get("s_complete_status"))) lm.addSearch("a.complete_status", f.get("s_complete_status"));
lm.addSearch("a.close_yn", f.get("s_close"));
if("C".equals(userKind)) lm.addWhere("a.course_id IN (" + manageCourses + ")");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.id, a.user_id, u.user_nm, u.login_id, u.etc1, u.etc2, u.etc3, u.etc4, u.etc5", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//포멧팅
String today = m.time("yyyyMMdd");
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("start_date_conv", m.time("yyyy.MM.dd", list.s("start_date")));
	list.put("end_date_conv", m.time("yyyy.MM.dd", list.s("end_date")));
	list.put("complete_date_conv", m.time("yyyy.MM.dd", list.s("complete_date")));
	String statusConv = "미판정";
	if("P".equals(list.s("complete_status"))) statusConv = "합격";
	else if("C".equals(list.s("complete_status"))) statusConv = "수료";
	else if("F".equals(list.s("complete_status"))) statusConv = "미수료";
	list.put("complete_status_conv", statusConv);
	list.put("complete_conv", statusConv);
	// 추가 커스텀 필드는 사용하지 않음
	list.put("complete_no_conv", ("P".equals(list.s("complete_status")) || "C".equals(list.s("complete_status"))) ? list.s("complete_no") : "");
	list.put("close_conv", "Y".equals(list.s("close_yn")) ? "종료" : "-");
	list.put("lecture_status_conv", "수강중");
	if(0 > m.diffDate("D", list.s("start_date"), today)) {
		list.put("lecture_status_conv", "수강대기");
	} else if(0 < m.diffDate("D", list.s("end_date"), today)) {
		list.put("lecture_status_conv", "수강완료");
	}

	list.put("progress_ratio_conv", m.nf(list.d("progress_ratio"), 0));
	list.put("exam_value_conv", m.nf(list.d("exam_value"), 0));
	list.put("homework_value_conv", m.nf(list.d("homework_value"), 0));
	list.put("forum_value_conv", m.nf(list.d("forum_value"), 0));
	list.put("etc_value_conv", m.nf(list.d("etc_value"), 0));

	//list.put("certificate_block", "Y".equals(list.s("complete_yn")) && "Y".equals(list.s("close_yn")));
	list.put("certificate_block", "Y".equals(list.s("complete_yn")));
	list.put("pass_block", "P".equals(list.s("complete_status")) && list.b("complete_yn"));
	list.put("complete_only_block", "C".equals(list.s("complete_status")) && list.b("complete_yn"));

	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//엑셀
if("excel".equals(m.rs("mode2"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "과정수료관리 (" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>no", "id=>수강생ID", "user_id=>회원아이디", "login_id=>로그인아이디", "user_nm=>회원명", "start_date_conv=>수강시작일", "end_date_conv=>수강마감일", "lecture_status_conv=>수강상태", "total_score=>총점", "progress_score=>진도점수", "progress_ratio_conv=>진도(100%기준)", "exam_score=>시험점수", "exam_value_conv=>시험점수(100점기준)", "homework_score=>과제점수", "homework_value_conv=>과제점수(100점기준)", "forum_score=>토론점수", "forum_value_conv=>토론점수(100점기준)", "etc_score=>기타점수", "etc_value_conv=>기타점수(100점기준)", "complete_status_conv=>결과상태", "complete_date_conv=>수료판정일", "complete_no_conv=>수료번호", "close_conv=>마감상태" }, "과정수료관리 (" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}


//출력
p.setBody("complete.complete_user");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());
p.setVar("template_block", 0 < cinfo.i("cert_template_id"));
p.setVar("cert_block", "Y".equals(cinfo.s("cert_complete_yn")));
p.setVar("pass_block", "Y".equals(cinfo.s("pass_yn")));
p.setVar("reorder_block", "Y".equals(cinfo.s("complete_no_yn")));
p.setVar("SITE_CONFIG", SiteConfig.getArr("user_etc_"));
p.setVar("course", cinfo);
p.setVar("total_survey_cnt", totalSurveyCnt);
p.display();

%>
