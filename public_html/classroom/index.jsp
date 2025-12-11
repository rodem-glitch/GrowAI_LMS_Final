<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
LessonDao lesson = new LessonDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseSectionDao courseSection = new CourseSectionDao();
CourseProgressDao courseProgress = new CourseProgressDao();
FileDao file = new FileDao();

ExamDao exam = new ExamDao();
HomeworkDao homework = new HomeworkDao();
ForumDao forum = new ForumDao();
SurveyDao survey = new SurveyDao();
ExamUserDao examUser = new ExamUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
ForumUserDao forumUser = new ForumUserDao();
SurveyUserDao surveyUser = new SurveyUserDao();

ClPostDao clPost = new ClPostDao();

//변수
boolean isPrev = false;
boolean isPrevExam = false;
boolean isPrevHomework = false;
boolean isPrevForum = false;
boolean isPrevSurvey = false;
int totalSurveyCnt = 0;
int submitSurveyCnt = 0;

//목록-모듈
//String[] moduleNames = {"exam=>시험", "homework=>과제", "forum=>토론", "survey=>설문"};
//courseModule.setDebug(out);
DataSet modules = courseModule.find("status = 1 AND course_id = " + courseId,
	"*"
	+ ", CASE WHEN module = 'exam' AND (SELECT count(*) FROM " + examUser.table + " WHERE exam_id = " + courseModule.table + ".module_id AND course_user_id = " + cuid + " AND submit_yn = 'Y' AND status = 1) = 1 THEN 'Y'"
	+ " WHEN module = 'homework' AND (SELECT count(*) FROM " + homeworkUser.table + " WHERE homework_id = " + courseModule.table + ".module_id AND course_user_id = " + cuid + " AND submit_yn = 'Y' AND status = 1) = 1 THEN 'Y'"
	+ " WHEN module = 'forum' AND (SELECT count(*) FROM " + forumUser.table + " WHERE forum_id = " + courseModule.table + ".module_id AND course_user_id = " + cuid + " AND submit_yn = 'Y' AND status = 1) = 1 THEN 'Y'"
	+ " WHEN module = 'survey' AND (SELECT count(*) FROM " + surveyUser.table + " WHERE survey_id = " + courseModule.table + ".module_id AND course_user_id = " + cuid + " AND status = 1) = 1 THEN 'Y'"
	+ " ELSE 'N' END submit_yn"
	, "chapter, start_date ASC");

while(modules.next()) {
	modules.put("module_conv", m.getValue(modules.s("module"), courseModule.evaluationsMsg));
	modules.put("module_nm_conv", m.cutString(modules.s("module_nm"), 30));

	//상태 [progress] (W : 대기, E : 종료, I : 수강중, R : 복습중)
	boolean isReady = false; //대기
	boolean isEnd = false; //완료
	if("1".equals(modules.s("apply_type"))) { //기간
		modules.put("start_date_conv", m.time(_message.get("format.datetime.dot"), modules.s("start_date")));
		modules.put("end_date_conv", m.time(_message.get("format.datetime.dot"), modules.s("end_date")));

		isReady = 0 > m.diffDate("I", modules.s("start_date"), now);
		isEnd = 0 < m.diffDate("I", modules.s("end_date"), now);

		modules.put("apply_type_1", true);
		modules.put("apply_type_2", false);
	} else if("2".equals(modules.s("apply_type"))) { //차시
		modules.put("apply_conv", modules.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + modules.i("chapter") }));
		if(modules.i("chapter") > 0 && 0 == courseProgress.findCount("course_id = " + courseId + " AND chapter = " + modules.i("chapter") + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;

		modules.put("apply_type_1", false);
		modules.put("apply_type_2", true);
	}

	String status = "-";
	if(modules.b("submit_yn")) status = _message.get("classroom.module.status.submit");
	else if(isReady) status = _message.get("classroom.module.status.waiting");
	else if(isEnd) status = _message.get("classroom.module.status.end");
	else status = _message.get("classroom.module.status.nosubmit");
	modules.put("status_conv", status);

	//처리-설문
	if("survey".equals(modules.s("module"))) {
		totalSurveyCnt++;
		if(modules.b("submit_yn")) submitSurveyCnt++;
	}
}

//목록
DataSet list = courseLesson.query(
	"SELECT a.* "
	+ ", l.onoff_type, l.lesson_nm, l.start_url, l.mobile_a, l.mobile_i, l.short_url, l.lesson_type, l.content_width, l.content_height, l.complete_time, l.total_time, l.total_page, l.status lesson_status "
	+ ", c.complete_yn, c.ratio, c.last_date, c.study_page, c.study_time, c.paragraph, c.complete_date, c.last_date, c.reg_date "
	+ ", cs.id section_id, cs.section_nm "
	+ ", ( CASE WHEN c.last_date BETWEEN '" + today + "000000' AND '" + today + "235959' THEN 'Y' ELSE 'N' END ) is_study "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " LEFT JOIN " + courseProgress.table + " c ON c.course_user_id = " + cuid + " AND a.lesson_id = c.lesson_id "
	+ " LEFT JOIN " + courseSection.table + " cs ON a.section_id = cs.id AND a.course_id = cs.course_id AND cs.status = 1 "
	+ " WHERE a.status = 1 AND a.course_id = " + courseId + " "
	+ " ORDER BY a.chapter ASC "
	//+ " ORDER BY a.chapter " + ("A".equals(cinfo.s("lesson_display_ord")) ? "ASC" : "DESC")
);

//학습제한-속진여부
boolean limitFlag = (cinfo.b("limit_lesson_yn") ? limitFlag = courseProgress.getLimitFlag(cuid, cinfo) : false);

//수강대기, 종료
boolean isWait = "W".equals(cuinfo.s("progress"));
boolean isEnd = "E".equals(cuinfo.s("progress"));
//boolean isRestudy = "R".equals(cuinfo.s("progress"));

int lastChapter = 1;
int lastSectionId = 0;
while(list.next()) {
	String[] paragraph = m.split(",", m.replace(list.s("paragraph"), "'", ""));
	Arrays.sort(paragraph);
	list.put("study_min", list.i("study_time") / 60);
	list.put("study_sec", list.i("study_time") % 60);
	list.put("complete_date_conv", m.time(_message.get("format.datetime.dot"), list.s("complete_date")));
	list.put("last_date_conv", m.time(_message.get("format.datetime.dot"), !"".equals(list.s("last_date")) ? list.s("last_date") : list.s("reg_date")));
	list.put("reg_date_conv", m.time(_message.get("format.datetime.dot"), list.s("reg_date")));
	list.put("study_page", list.i("study_page"));
	list.put("paragraph_conv", m.join("<br>", paragraph));
	list.put("over_block", list.i("study_time") > (list.i("total_time") * 60));

	if(list.b("complete_yn")) lastChapter = list.i("chapter") + 1;
	//list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 50));
	list.put("lesson_nm_conv", list.s("lesson_nm"));
	list.put("study_date", !"".equals(list.s("last_date")) ? m.time(_message.get("format.datetime.dot"), list.s("last_date")) : "-");
	list.put("complete_conv", list.b("complete_yn") ? "Y" : "N");
	//list.put("attend_cnt", list.i("attend_cnt"));
	list.put("lesson_type_conv", m.getValue(list.s("lesson_type"), lesson.offlineTypesMsg));

	list.put("ratio_conv", m.nf(list.d("ratio"), 0));

	if("N".equals(list.s("onoff_type"))) {
		list.put("online_block", true);
		list.put("start_date_conv", m.time(_message.get("format.date.dot"), list.s("start_date")));
		list.put("end_date_conv", m.time(_message.get("format.date.dot"), list.s("end_date")));
		if(list.s("start_date").length() == 8 && list.s("end_date").length() == 8 && list.s("start_time").length() == 6 && list.s("end_time").length() == 6) {
			list.put("start_date_conv", m.time(_message.get("format.datetime.dot"), list.s("start_date") + list.s("start_time")));
			list.put("end_date_conv", m.time(_message.get("format.datetime.dot"), list.s("end_date") + list.s("end_time")));
		}
		list.put("date_conv", list.s("start_date_conv") + " 부터 <br> " + list.s("end_date_conv") + " 까지");
	} else if("F".equals(list.s("onoff_type"))) {
		list.put("online_block", false);
		list.put("start_date_conv", m.time(_message.get("format.date.dot"), list.s("start_date")));
		list.put("end_date_conv", m.time("HH:mm", list.s("start_date") + list.s("end_time")));
		list.put("date_conv", list.s("start_date_conv") + " <br> " + m.time("HH:mm", list.s("start_date") + list.s("start_time")) + " - " + list.s("end_date_conv"));
	} else if("T".equals(list.s("onoff_type"))) {
		list.put("online_block", true);
		list.put("date_conv", "-");
		list.put("start_date_conv", m.time(_message.get("format.date.dot"), list.s("start_date")));
		list.put("end_date_conv", m.time(_message.get("format.date.dot"), list.s("end_date")));
		if(list.s("start_date").length() == 8 && list.s("end_date").length() == 8 && list.s("start_time").length() == 6 && list.s("end_time").length() == 6) {
			list.put("start_date_conv", m.time(_message.get("format.datetime.dot"), list.s("start_date") + list.s("start_time")));
			list.put("end_date_conv", m.time(_message.get("format.datetime.dot"), list.s("end_date") + list.s("end_time")));
			list.put("date_conv", list.s("start_date_conv") + " 부터 <br> " + list.s("end_date_conv") + " 까지");
		}
	}

	DataSet files = file.getFileList(list.i("lesson_id"), "lesson");
	while(files.next()) {
		files.put("file_ext", file.getFileExt(files.s("filename")));
		files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
		files.put("ext", file.getFileIcon(files.s("filename")));
		files.put("ek", m.encrypt(files.s("id") + m.time("yyyyMMdd")));
		files.put("cek", m.encrypt(cuid + files.s("id") + list.s("lesson_id") + m.time("yyyyMMdd")));
		files.put("sep", !files.b("__last") ? "<br>" : "");
		files.put("filesize_conv", file.getFileSize(files.l("filesize")));
	}

	list.put(".files", files);
	list.put("file_block", files.size() > 0);

	if(cinfo.b("limit_ratio_yn")) {
		double limitStudyTime = list.i("total_time") * 60 * cinfo.d("limit_ratio");
		list.put("limit_study_min", (int)limitStudyTime / 60);
		list.put("limit_study_sec", (int)limitStudyTime % 60);
	}

	boolean isOpen = true;

	if(isOpen && limitFlag) { //속진제한
		isOpen = "Y".equals(list.s("is_study"));
		list.put("msg", cinfo.i("limit_day") + "일 " + cinfo.i("limit_lesson") + "차시로 학습이 제한되어 있습니다.\\n관리자에게 문의하십시오.");
	}
	if(isOpen && cinfo.b("period_yn")) { //수강기간 제한

		boolean isTwoway = "T".equals(list.s("onoff_type"));
		String startDateTime = list.s("start_date") + (list.s("start_time").length() == 6 ? list.s("start_time") : "000000");
		String endDateTime = list.s("end_date") + (list.s("end_time").length() == 6 ? list.s("end_time") : "235959");
		long nowDateTime = m.parseLong(now);

		if(isTwoway) {
			//화상강의에는 복습이 없음
			isOpen = m.parseLong(m.time("yyyyMMddHHmmss", m.addDate("I", -30, startDateTime))) <= nowDateTime && m.parseLong(endDateTime) >= nowDateTime;
		} else {
			//복습 허용시 강의수강 가능
			isOpen = m.parseLong(startDateTime) <= nowDateTime && (cinfo.b("restudy_yn") || m.parseLong(endDateTime) >= nowDateTime);
		}
		list.put("msg", "학습기간이 아닙니다.\\n관리자에게 문의하십시오.");

	}
	if(isOpen && cinfo.b("lesson_order_yn")) { //순차적용
		isOpen = lastChapter >= list.i("chapter");
		list.put("msg", (list.i("chapter") - 1) + "장을 학습하셔야 합니다.\\n(순차학습 과정입니다.)\\n관리자에게 문의하십시오.");
	}

	if("Y".equals(list.s("complete_yn")) && "N".equals(list.s("onoff_type"))) isOpen = true;

	if(cinfo.b("limit_ratio_yn") && (list.i("total_time") * 60 * cinfo.d("limit_ratio") < list.d("study_time"))) { //배수제한
		//total_time * limit_ratio < study_time
		isOpen = false;
		list.put("msg", "허용된 학습량을 초과하였습니다.");
	}

	if(isEnd || isWait) { //수강 대기, 종료
		isOpen = false;
		list.put("msg", "수강기간이 아닙니다.");
	}

	if(isPrev) {
		isOpen = false;
		if(isPrevExam) list.put("msg", "선행해야 하는 시험이 있습니다.");
		else if(isPrevHomework) list.put("msg", "선행해야 하는 과제가 있습니다.");
		else if(isPrevForum) list.put("msg", "선행해야 하는 토론이 있습니다.");
		else if(isPrevSurvey) list.put("msg", "선행해야 하는 설문이 있습니다.");
	}

	if(isOpen && 1 != list.i("lesson_status")) {
		isOpen = false;
		list.put("msg", _message.get("alert.lesson.stopped"));
	}

	list.put("open_block", isOpen);

	if(lastSectionId != list.i("section_id") && 0 < list.i("section_id")) {
		lastSectionId = list.i("section_id");
		list.put("section_block", true);
	} else {
		list.put("section_block", false);
	}
	
	list.put("download_block", siteinfo.b("download_yn") && "05".equals(list.s("lesson_type")));
}

//정렬
if(!"A".equals(cinfo.s("lesson_display_ord"))) {
	list.sort("chapter", "desc");
}

//선행
DataSet prev = new DataSet(); prev.addRow();
if(isPrev) {
	if(isPrevExam) {
		prev.put("msg", "선행해야 하는 시험이 있습니다. 시험방으로 이동합니다.");
		prev.put("link", "exam.jsp?cuid=" + cuid);
	} else if(isPrevHomework) {
		prev.put("msg", "선행해야 하는 과제가 있습니다. 과제방으로 이동합니다.");
		prev.put("link", "homework.jsp?cuid=" + cuid);
	} else if(isPrevForum) {
		prev.put("msg", "선행해야 하는 토론이 있습니다. 토론방으로 이동합니다.");
		prev.put("link", "forum.jsp?cuid=" + cuid);
	} else if(isPrevSurvey) {
		prev.put("msg", "선행해야 하는 설문이 있습니다. 설문방으로 이동합니다.");
		prev.put("link", "survey.jsp?cuid=" + cuid);
	}
}

//남은일수
cuinfo.put("term_day", "W".equals(progress) ? "학습대기" : ("E".equals(progress) ? "학습종료" : (alltime ? "상시" : m.diffDate("D", today, cuinfo.s("end_date")) + "일")));
cuinfo.put("t_day", m.diffDate("D", cuinfo.s("start_date"), cuinfo.s("end_date"))); //전체일수
cuinfo.put("d_day", "W".equals(progress) ? 0 : ("E".equals(progress) ? cuinfo.i("t_day") : cuinfo.s("past_day"))); //경과일수

//진도율
cuinfo.put("avg_progress_ratio", cu.getOne("SELECT AVG(progress_ratio) avg FROM " + cu.table + " WHERE course_id = '" + courseId + "' AND status IN (1,3)"));
cuinfo.put("my_progress", cuinfo.d("progress_ratio") == 0 ? "0" : m.nf(190 * cuinfo.d("progress_ratio") / 100, 0));
cuinfo.put("avg_progress", cuinfo.d("avg_progress_ratio") == 0 ? "0" : m.nf(190 * cuinfo.d("avg_progress_ratio") / 100, 0));
cuinfo.put("avg_progress_ratio" , m.nf(cuinfo.d("avg_progress_ratio"), 1));
cuinfo.put("progress_ratio" , m.nf(cuinfo.d("progress_ratio"), 1));

//정보-최근공지
DataSet notices = clPost.find("site_id = " + siteId + " AND course_id = " + cinfo.i("id") + " AND board_cd = 'notice' AND depth = 'A' AND display_yn = 'Y' AND status = 1", "*", "thread ASC", 5);
while(notices.next()) {
	notices.put("subject_conv", m.cutString(notices.s("subject"), 50));
	notices.put("reg_date_conv", m.time(_message.get("format.date.dot"), notices.s("reg_date")));
}

//정보-QNA
DataSet qnas = clPost.find("site_id = " + siteId + " AND course_id = " + cinfo.i("id") + " AND board_cd = 'qna' AND depth = 'A' AND display_yn = 'Y' AND status = 1", "*", "thread ASC", 5);
while(qnas.next()) {
	qnas.put("subject_conv", m.cutString(qnas.s("subject"), 50));
	qnas.put("reg_date_conv", m.time(_message.get("format.date.dot"), qnas.s("reg_date")));
}

//사이트설정
DataSet siteconfig = SiteConfig.getArr("classroom_");

//출력
p.setLayout(ch);
p.setBody("classroom.index");
p.setVar("query", m.qs());

p.setLoop("list", list);
p.setLoop("module_list", modules);
p.setLoop("notice_list", notices);
p.setLoop("qna_list", qnas);
p.setVar("cuinfo", cuinfo);

/* p.setVar(
	"renew_block"
	, cinfo.b("renew_yn") && "A".equals(cinfo.s("course_type")) && "N".equals(cinfo.s("onoff_type"))
	&& (0 == cinfo.i("renew_max_cnt") || cinfo.i("renew_max_cnt") > cuinfo.i("renew_cnt")) && (0 <= m.diffDate("D", m.time("yyyyMMdd"), cuinfo.s("end_date")))
); */
p.setVar("renew_block", courseUser.setRenewBlock(cuinfo.getRow()));
p.setVar("prev_block", isPrev);
p.setVar("prev", prev);

p.setVar("section_colspan", 6 + (cinfo.b("period_yn") ? 1 : 0));

p.setVar("push_survey_block"
	, "I".equals(progress) && cinfo.b("push_survey_yn") //&& !cuinfo.b("complete_yn")
	&& (cinfo.d("limit_progress") <= cuinfo.d("progress_ratio"))
	&& totalSurveyCnt > submitSurveyCnt
);

p.setVar("SITE_CONFIG", siteconfig);
p.display();

%>