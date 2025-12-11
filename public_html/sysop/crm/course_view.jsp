<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int cuid = m.ri("cuid");
if(cuid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseRenewDao courseRenew = new CourseRenewDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseSectionDao courseSection = new CourseSectionDao();
CourseProgressDao courseProgress = new CourseProgressDao();
CourseModuleDao courseModule = new CourseModuleDao();
LessonDao lesson = new LessonDao();

ExamUserDao examUser = new ExamUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
ForumUserDao forumUser = new ForumUserDao();
SurveyUserDao surveyUser = new SurveyUserDao();

OrderItemDao orderItem = new OrderItemDao();

//변수
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");


//정보-수강생
DataSet cuinfo = courseUser.query(
	"SELECT a.* "
	+ ", (CASE WHEN '" + today + "' BETWEEN a.start_date AND a.end_date THEN 'Y' ELSE 'N' END) is_study "
	+ ", u.user_nm, u.login_id "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " AND u.status != -1 "
	+ " WHERE a.id = " + cuid + " AND a.user_id = " + uid + " "
);
if(!cuinfo.next()) { m.jsError("해당 수강생정보가 없습니다."); return; }
int courseId = cuinfo.i("course_id");
user.maskInfo(cuinfo);

//기록-개인정보조회
if("".equals(m.rs("mode")) && cuinfo.size() > 0 && !isBlindUser) _log.add("V", "수강정보", cuinfo.size(), "이러닝 운영", cuinfo);

//정보-과정
DataSet cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + " AND status != -1");
if(!cinfo.next()) { m.jsAlert("해당 과정정보가 없습니다."); return; }

//폼체크
f.addElement("start_date", null, "hname:'학습 시작일', required:'Y'");
f.addElement("end_date", null, "hname:'학습 종료일', required:'Y'");

//수강기간 수정
if(m.isPost() && f.validate()) {

	courseUser.item("start_date", m.time("yyyyMMdd", f.get("start_date")));
	courseUser.item("end_date", m.time("yyyyMMdd",f.get("end_date")));
	courseUser.item("mod_date", now);
	if(!courseUser.update("id = " + cuid + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	courseRenew.item("site_id", siteId);
	courseRenew.item("course_user_id", cuid);
	courseRenew.item("renew_type", "S");
	courseRenew.item("start_date", m.time("yyyyMMdd", f.get("start_date")));
	courseRenew.item("end_date", m.time("yyyyMMdd",f.get("end_date")));
	courseRenew.item("user_id", userId);
	courseRenew.item("order_item_id", -99);
	courseRenew.item("reg_date", now);
	courseRenew.item("status", 1);
	if(!courseRenew.insert()) { m.jsError("등록하는 중 오류가 발생했습니다."); return; }

	//이동
	m.jsAlert("학습기간을 수정했습니다.");
	m.jsReplace("course_list.jsp?" + m.qs("cuid"));
	return;
}

//목록-차시
DataSet lessons = courseLesson.query(
	"SELECT a.*"
	+ ", l.lesson_nm, l.lesson_type, l.total_time, l.complete_time "
	+ ", p.course_user_id, p.complete_yn, IFNULL(NULLIF(p.study_time, ''), 0) study_time, IFNULL(NULLIF(p.last_time, ''), 0) last_time, p.ratio, p.complete_date, p.last_date, p.paragraph "
	+ ", cs.id section_id, cs.section_nm "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " LEFT JOIN " + courseSection.table + " cs ON a.section_id = cs.id AND cs.status = 1 "
	+ " LEFT JOIN " + courseProgress.table + " p ON "
		+ " p.course_user_id = " + cuid + " AND p.lesson_id = a.lesson_id "
	+ " WHERE a.status = 1 AND a.course_id = " + courseId + " "
	+ " ORDER BY a.chapter ASC "
);


//처리-전체완료
if("all".equals(m.rs("mode"))) {
	lessons.first();
	while(lessons.next()) {
		if(lessons.i("course_user_id") != 0) {
			if(!lessons.b("complete_yn")) {
				courseProgress.item("ratio", 100);
				courseProgress.item("complete_yn", "Y");
				//courseProgress.item("last_date", now);
				courseProgress.item("complete_date", now);
				courseProgress.item("change_user_id", userId);
				if(!courseProgress.update("course_id = " + courseId + " AND lesson_id = " + lessons.s("lesson_id") + " AND course_user_id = " + cuid + "" )) { }
			}
		} else {
			courseProgress.item("course_id", courseId);
			courseProgress.item("lesson_id", lessons.i("lesson_id"));
			courseProgress.item("chapter", lessons.i("chapter"));
			courseProgress.item("course_user_id", cuid);

			courseProgress.item("user_id", cuinfo.i("user_id"));
			courseProgress.item("lesson_type", lessons.s("lesson_type"));
			courseProgress.item("study_page", 0);
			courseProgress.item("study_time", 0);
			courseProgress.item("curr_page", "");
			courseProgress.item("curr_time", 0);
			courseProgress.item("last_time", 0);
			courseProgress.item("paragraph", "");
			courseProgress.item("ratio", 100);
			courseProgress.item("complete_yn", "Y");
			courseProgress.item("complete_date", now);
			courseProgress.item("view_cnt", 1);
			//courseProgress.item("last_date", now);
			courseProgress.item("change_user_id", userId);
			courseProgress.item("reg_date", now);
			courseProgress.item("status", 1);
			courseProgress.item("site_id", siteId);

			if(!courseProgress.insert()) { }
		}
		courseProgress.clear();
	}

	courseUser.setProgressRatio(cuid);
	courseUser.setCourseUserScore(cuid, "progress"); //점수일괄업데이트
	if(cinfo.b("complete_auto_yn")) courseUser.closeUser(cuid, userId);

	m.jsAlert("처리되었습니다.");
	m.jsReplace("course_view.jsp?" + m.qs("mode,chapter,lid"));
	return;


//처리-완료
} else if("complete".equals(m.rs("mode"))) {

	//기본키
	int chapter = m.ri("chapter");
	int lid = m.ri("lid");
	if(chapter == 0 || lid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	DataSet linfo = courseLesson.query(
		"SELECT a.*"
		+ ", l.lesson_nm, l.lesson_type "
		+ ", p.course_user_id, p.complete_yn, p.ratio, p.complete_date, p.last_date "
		+ " FROM " + courseLesson.table + " a "
		+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
		+ " LEFT JOIN " + courseProgress.table + " p ON "
			+ " p.course_id = a.course_id AND p.lesson_id = a.lesson_id AND p.course_user_id = " + cuid + " "
		+ " WHERE a.status = 1 AND a.course_id = " + courseId + " AND a.lesson_id = " + lid
	);
	if(!linfo.next()) { m.jsError("해당 정보가 없습니다."); return; }

	//제한
	if(linfo.b("complete_yn")) { m.jsError("이미 완료된 차시입니다."); return; }

	if(linfo.i("course_user_id") != 0) {

		if(!linfo.b("complete_yn")) {
			courseProgress.item("ratio", 100);
			courseProgress.item("complete_yn", "Y");
			//courseProgress.item("last_date", now);
			courseProgress.item("complete_date", now);
			courseProgress.item("change_user_id", userId);
			if(!courseProgress.update("course_id = " + courseId + " AND lesson_id = " + lid + " AND course_user_id = " + cuid + "" )) {
				m.jsError("완료 처리하는 하는 중 오류가 발생했습니다.");
				return;
			}
		}

	} else {
		courseProgress.item("course_id", courseId);
		courseProgress.item("lesson_id", linfo.i("lesson_id"));
		courseProgress.item("chapter", linfo.i("chapter"));
		courseProgress.item("course_user_id", cuid);

		courseProgress.item("user_id", cuinfo.i("user_id"));
		courseProgress.item("lesson_type", linfo.s("lesson_type"));
		courseProgress.item("study_page", 0);
		courseProgress.item("study_time", 0);
		courseProgress.item("curr_page", "");
		courseProgress.item("curr_time", 0);
		courseProgress.item("last_time", 0);
		courseProgress.item("paragraph", "");
		courseProgress.item("ratio", 100);
		courseProgress.item("complete_yn", "Y");
		courseProgress.item("complete_date", now);
		courseProgress.item("view_cnt", 1);
		//courseProgress.item("last_date", now);
		courseProgress.item("change_user_id", userId);
		courseProgress.item("reg_date", now);
		courseProgress.item("status", 1);
		courseProgress.item("site_id", siteId);

		if(!courseProgress.insert()) { m.jsError("완료 처리하는 하는 중 오류가 발생했습니다.");	return;	}
	}

	courseUser.setProgressRatio(cuid);
	courseUser.setCourseUserScore(cuid, "progress"); //점수일괄업데이트
	if(cinfo.b("complete_auto_yn")) courseUser.closeUser(cuid, userId);

	m.jsAlert("처리되었습니다.");
	m.jsReplace("course_view.jsp?" + m.qs("mode,chapter,lid"));
	return;

//처리-진도삭제
} else if("undo".equals(m.rs("mode"))) {

	//기본키
	int chapter = m.ri("chapter");
	int lid = m.ri("lid");
	if(chapter == 0 || lid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	DataSet linfo = courseLesson.query(
		"SELECT a.*"
		+ ", l.lesson_nm, l.lesson_type "
		+ ", p.course_user_id, p.complete_yn, p.ratio, p.complete_date, p.last_date "
		+ " FROM " + courseLesson.table + " a "
		+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
		+ " INNER JOIN " + courseProgress.table + " p ON "
			+ " p.course_id = a.course_id AND p.lesson_id = a.lesson_id AND p.course_user_id = " + cuid + " "
		+ " WHERE a.status = 1 AND a.course_id = " + courseId + " AND a.lesson_id = " + lid
	);
	if(!linfo.next()) { m.jsError("해당 정보가 없습니다."); return; }

	//제한
	if(!linfo.b("complete_yn")) { m.jsError("완료된 차시가 아닙니다."); return; }

	courseProgress.item("study_page", 0);
	courseProgress.item("study_time", 0);
	courseProgress.item("curr_page", "");
	courseProgress.item("curr_time", 0);
	courseProgress.item("last_time", 0);
	courseProgress.item("paragraph", "");
	courseProgress.item("ratio", 0);
	courseProgress.item("complete_yn", "N");
	courseProgress.item("complete_date", "");
	courseProgress.item("last_date", "");
	courseProgress.item("change_user_id", userId);
	if(!courseProgress.update("course_id = " + courseId + " AND lesson_id = " + lid + " AND course_user_id = " + cuid + "" )) {
		m.jsError("진도삭제 처리하는 하는 중 오류가 발생했습니다.");
		return;
	}

	courseUser.setProgressRatio(cuid);
	courseUser.setCourseUserScore(cuid, "progress"); //점수일괄업데이트

	m.jsAlert("처리되었습니다.");
	m.jsReplace("course_view.jsp?" + m.qs("mode,chapter,lid"));
	return;

}

//포맷팅
cuinfo.put("status_conv", m.getItem(cuinfo.s("status"), courseUser.statusList));
cuinfo.put("period_block", "Y".equals(cuinfo.s("period_yn")));
cuinfo.put("total_score_conv", m.nf(cuinfo.d("total_score"), 2));
cuinfo.put("progress_ratio_conv", m.nf(cuinfo.d("progress_ratio"), 2));
cuinfo.put("exam_value_conv", m.nf(cuinfo.d("exam_value"), 2));
cuinfo.put("homework_value_conv", m.nf(cuinfo.d("homework_value"), 2));
cuinfo.put("forum_value_conv", m.nf(cuinfo.d("forum_value"), 2));
cuinfo.put("etc_value_conv", m.nf(cuinfo.d("etc_value"), 2));

cuinfo.put("progress_score_conv", m.nf(cuinfo.d("progress_score"), 2));
cuinfo.put("exam_score_conv", m.nf(cuinfo.d("exam_score"), 2));
cuinfo.put("homework_score_conv", m.nf(cuinfo.d("homework_score"), 2));
cuinfo.put("forum_score_conv", m.nf(cuinfo.d("forum_score"), 2));
cuinfo.put("etc_score_conv", m.nf(cuinfo.d("etc_score"), 2));

cuinfo.put("complete_conv", cuinfo.b("complete_yn") ? "수료" : "-");
cuinfo.put("close_conv", cuinfo.b("close_yn") ? "마감" : "미마감");

cuinfo.put("start_date_conv", m.time("yyyy-MM-dd", cuinfo.s("start_date")));
cuinfo.put("end_date_conv", m.time("yyyy-MM-dd", cuinfo.s("end_date")));
cuinfo.put("mod_date_conv", !"".equals(cuinfo.s("mod_date")) ? m.time("yyyy.MM.dd HH:mm", cuinfo.s("mod_date")) : "-");
cuinfo.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", cuinfo.s("reg_date")));
cuinfo.put("close_date_conv", !"".equals(cuinfo.s("close_date")) ? m.time("yyyy.MM.dd HH:mm", cuinfo.s("close_date")) : "-");
cuinfo.put("close_user_nm", !"".equals(cuinfo.s("close_user_nm")) ? cuinfo.s("close_user_nm") : "-");

//평가항목
DataSet evaluations = m.arr2loop(courseModule.evaluations);
while(evaluations.next()) {
	cuinfo.put(evaluations.s("id") + "_cnt", 0);
	cuinfo.put(evaluations.s("id") + "_join_cnt", 0);
}
DataSet evalCounts = courseModule.query(
	"SELECT a.module, COUNT(*) cnt "
	+ " FROM " + courseModule.table + " a "
	+ " WHERE a.course_id = " + courseId + " AND status = 1 "
	+ " GROUP BY a.module "
);
while(evalCounts.next()) {
	cuinfo.put(evalCounts.s("module") + "_cnt", evalCounts.i("cnt"));
}


//참여
cuinfo.put("exam_join_cnt", examUser.findCount("course_user_id = " + cuid + " AND status = 1 AND submit_yn = 'Y'"));
cuinfo.put("homework_join_cnt", homeworkUser.findCount("course_user_id = " + cuid + " AND status = 1 AND submit_yn = 'Y'"));
cuinfo.put("forum_join_cnt", forumUser.findCount("course_user_id = " + cuid + " AND status = 1 AND submit_yn = 'Y'"));
cuinfo.put("survey_join_cnt", surveyUser.findCount("course_user_id = " + cuid + " AND status = 1"));


//포맷팅
int lastSectionId = 0;
while(lessons.next()) {
	lessons.put("subject_conv", m.cutString(lessons.s("subject"), 60));
	lessons.put("total_second", m.nf(lessons.i("total_time") * 60));
	lessons.put("complete_second", m.nf(lessons.i("complete_time") * 60));
	lessons.put("last_minute", m.nf(lessons.i("last_time") / 60.0, 1));
	lessons.put("last_time_conv", m.nf(lessons.i("last_time")));
	lessons.put("study_minute", m.nf(lessons.i("study_time") / 60.0, 1));
	lessons.put("study_time_conv", m.nf(lessons.i("study_time")));
	lessons.put("study_ratio_conv", lessons.i("total_time") > 0 ? m.nf(lessons.i("study_time") / (lessons.i("total_time") * 60.0) * 100, 1) : 100);
	lessons.put("complete_time_block", lessons.i("complete_time") * 60 <= lessons.i("study_time") && lessons.i("complete_time") * 60 <= lessons.i("last_time"));
	lessons.put("last_date_conv", !"".equals(lessons.s("last_date")) ? m.time("yyyy.MM.dd HH:mm", lessons.s("last_date")) : "-");
	lessons.put("complete_date_conv", !"".equals(lessons.s("complete_date")) ? m.time("yyyy.MM.dd HH:mm", lessons.s("complete_date")) : "-");
	lessons.put("ratio_conv", m.nf(lessons.d("ratio"), 2));
	lessons.put("complete_conv", lessons.b("complete_yn") ? "완료" : "-");
	lessons.put("ROW_CLASS", lessons.b("complete_time_block") ? "" : "important");

	if(lastSectionId != lessons.i("section_id") && 0 < lessons.i("section_id")) {
		lastSectionId = lessons.i("section_id");
		lessons.put("section_block", true);
	} else {
		lessons.put("section_block", false);
	}
}

//목록-학습기간변경이력
DataSet crlist = courseRenew.query(
	" SELECT a.*, u.user_nm, u.login_id, oi.order_id "
	+ " FROM "  + courseRenew.table + " a "
	+ " LEFT JOIN " + user.table + " u ON u.id = a.user_id "
	+ " LEFT JOIN " + orderItem.table + " oi ON oi.id = a.order_item_id "
	+ " WHERE a.course_user_id = " + cuid + " AND a.status = 1 "
	+ " ORDER BY a.id ASC "
);
while(crlist.next()) {
	crlist.put("renew_type_conv", m.getItem(crlist.s("renew_type"), courseRenew.types));
	crlist.put("order_block", !"S".equals(crlist.s("renew_type")));

	crlist.put("start_date_conv", m.time("yyyy.MM.dd", crlist.s("start_date")));
	crlist.put("end_date_conv", m.time("yyyy.MM.dd", crlist.s("end_date")));
	crlist.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", crlist.s("reg_date")));
}

//출력
p.setLayout(ch);
p.setBody("crm.course_view");
p.setVar("p_title", "수강정보");
p.setVar("query", m.qs("mode, cp, pchapter"));
p.setVar("list_query", m.qs("cuid, mode, cp, pchapter"));
p.setVar("query", m.qs());

p.setVar("cuinfo", cuinfo);
p.setLoop("lessons", lessons);
p.setLoop("crlist", crlist);
p.setVar("course", cinfo);

p.setVar("tab_course", "current");
p.display();

%>