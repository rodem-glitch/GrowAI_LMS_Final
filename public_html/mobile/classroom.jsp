<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init_classroom.jsp" %><%

//객체
LessonDao lesson = new LessonDao();
CourseLessonDao courseLesson = new CourseLessonDao();
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

//변수
boolean isPrev = false;
boolean isPrevExam = false;
boolean isPrevHomework = false;
boolean isPrevForum = false;
boolean isPrevSurvey = false;

/*
//목록-시험
DataSet exams = courseModule.query(
	"SELECT a.*, e.exam_nm, u.user_id "
	+ " FROM " + courseModule.table + " a "
	+ " LEFT JOIN " + examUser.table + " u ON "
		+ " u.exam_id = a.module_id AND u.course_user_id = " + cuid + " AND u.user_id = " + userId + " "
		+ " AND u.submit_yn = 'Y' AND u.status = 1 "
	+ " LEFT JOIN " + exam.table + " e ON a.module_id = e.id "
	+ " WHERE a.course_id = " + courseId + " AND a.status = 1 "
	+ " AND a.apply_type = '2' AND a.module = 'exam' AND a.chapter = 0 "
);
while(exams.next()) {
	if("".equals(exams.s("user_id"))) {
		isPrev = true;
		isPrevExam = true;
	}
}

//목록-과제
DataSet homeworks = courseModule.query(
	"SELECT a.*, h.homework_nm, u.user_id "
	+ " FROM " + courseModule.table + " a "
	+ " LEFT JOIN " + homeworkUser.table + " u ON "
		+ " u.homework_id = a.module_id AND u.course_user_id = " + cuid + " AND u.user_id = " + userId + " "
		+ " AND u.submit_yn = 'Y' AND u.status = 1 "
	+ " LEFT JOIN " + homework.table + " h ON a.module_id = h.id "
	+ " WHERE a.course_id = " + courseId + " AND a.status = 1 "
	+ " AND a.apply_type = '2' AND a.module = 'homework' AND a.chapter = 0 "
);
while(homeworks.next()) {
	if("".equals(homeworks.s("user_id"))) {
		isPrev = true;
		isPrevHomework = true;
	}
}

//목록-토론
DataSet forums = courseModule.query(
	"SELECT a.*, f.forum_nm, u.user_id "
	+ " FROM " + courseModule.table + " a "
	+ " LEFT JOIN " + forumUser.table + " u ON "
		+ " u.forum_id = a.module_id AND u.course_user_id = " + cuid + " AND u.user_id = " + userId + " "
		+ " AND u.submit_yn = 'Y' AND u.status = 1 "
	+ " LEFT JOIN " + forum.table + " f ON a.module_id = f.id "
	+ " WHERE a.course_id = " + courseId + " AND a.status = 1 "
	+ " AND a.apply_type = '2' AND a.module = 'forum' AND a.chapter = 0 "
);
while(forums.next()) {
	if("".equals(forums.s("user_id"))) {
		isPrev = true;
		isPrevForum = true;
	}
}

//목록-설문
DataSet surveys = courseModule.query(
	"SELECT a.*, s.survey_nm, u.user_id "
	+ " FROM " + courseModule.table + " a "
	+ " LEFT JOIN " + surveyUser.table + " u ON "
		+ " u.survey_id = a.module_id AND u.course_user_id = " + cuid + " AND u.user_id = " + userId + " "
		+ " AND u.status = 1 "
	+ " LEFT JOIN " + survey.table + " s ON a.module_id = s.id "
	+ " WHERE a.course_id = " + courseId + " AND a.status = 1 "
	+ " AND a.apply_type = '2' AND a.module = 'survey' AND a.chapter = 0 "
);
while(surveys.next()) {
	if("".equals(surveys.s("user_id"))) {
		isPrev = true;
		isPrevSurvey = true;
	}
}
*/

//목록
DataSet list = courseLesson.query(
	"SELECT a.* "
	+ ", l.onoff_type, l.lesson_nm, l.start_url, l.mobile_a, l.mobile_i, l.lesson_type, l.content_width, l.content_height, l.complete_time, l.total_time, l.total_page, l.status lesson_status "
	+ ", c.complete_yn, c.ratio, c.last_date, c.study_page, c.study_time, c.paragraph, c.complete_date "
	+ ", cs.id section_id, cs.section_nm "
	+ ", ( CASE WHEN c.last_date BETWEEN '" + today + "000000' AND '" + today + "235959' THEN 'Y' ELSE 'N' END ) is_study "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " LEFT JOIN " + courseProgress.table + " c ON c.course_user_id = " + cuid + " AND a.lesson_id = c.lesson_id "
	+ " LEFT JOIN " + courseSection.table + " cs ON a.section_id = cs.id AND a.course_id = cs.course_id AND cs.status = 1 "
	+ " WHERE a.status = 1 AND a.course_id = " + courseId + " "
	+ " ORDER BY a.chapter " + ("A".equals(cinfo.s("lesson_display_ord")) ? "ASC" : "DESC")
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
	list.put("study_min", list.i("study_time") / 60);
	list.put("study_sec", list.i("study_time") % 60);
	list.put("complete_date_conv", m.time(_message.get("format.datetime.dot"), list.s("complete_date")));
	list.put("study_page", list.i("study_page"));
	list.put("paragraph_conv", m.replace(list.s("paragraph"), "'", ""));
	list.put("over_block", list.i("study_time") > (list.i("total_time") * 60));

	if(list.b("complete_yn")) lastChapter = list.i("chapter") + 1;
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 30));
	list.put("study_date", !"".equals(list.s("last_date")) ? m.time(_message.get("format.datetime.dot"), list.s("last_date")) : "-");
	list.put("complete_conv", list.b("complete_yn") ? "Y" : "N");
	//list.put("attend_cnt", list.i("attend_cnt"));
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.offlineTypes));

	list.put("ratio_conv", m.nf(list.d("ratio"), 1));

	if("N".equals(list.s("onoff_type"))) {
		list.put("online_block", true);
		list.put("start_date_conv", m.time(_message.get("format.date.dot"), list.s("start_date")));
		list.put("end_date_conv", m.time(_message.get("format.date.dot"), list.s("end_date")));
		list.put("date_conv", list.s("start_date_conv") + " - " + list.s("end_date_conv"));
	} else if("F".equals(list.s("onoff_type"))) {
		list.put("online_block", false);
		list.put("start_date_conv", m.time(_message.get("format.datetime.dot"), list.s("start_date") + list.s("start_time")));
		list.put("end_date_conv", m.time("HH:mm", list.s("start_date") + list.s("end_time")));
		list.put("date_conv", list.s("start_date_conv") + " - " + list.s("end_date_conv"));
	}

	list.put("class_conv", !"Y".equals(list.s("complete_yn")) ? "my_btnstyle04" : "my_btnstyle03");

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
		list.put("msg", "1일 " +  cinfo.i("limit_lesson") + "차시로 학습이 제한되어 있습니다.\\n관리자에게 문의하십시오.");
	}
	if(isOpen && cinfo.b("period_yn")) { //수강기간 제한
		isOpen = list.i("start_date") <= m.parseInt(today) && (cinfo.b("restudy_yn") || list.i("end_date") >= m.parseInt(today));
		list.put("msg", "학습기간이 아닙니다.\\n관리자에게 문의하십시오.");
	}
	if(isOpen && cinfo.b("lesson_order_yn")) { //순차적용
		isOpen = lastChapter >= list.i("chapter");
		list.put("msg", (list.i("chapter") - 1) + "장을 학습하셔야 합니다.\\n(순차학습 과정입니다.)\\n관리자에게 문의하십시오.");
	}

	if("Y".equals(list.s("complete_yn"))) isOpen = true;

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
cuinfo.put("my_progress", cuinfo.d("progress_ratio") == 0 ? "0" : m.nf(100 * cuinfo.d("progress_ratio") / 100, 0));
cuinfo.put("avg_progress", cuinfo.d("avg_progress_ratio") == 0 ? "0" : m.nf(100 * cuinfo.d("avg_progress_ratio") / 100, 0));
cuinfo.put("avg_progress_ratio" , m.nf(cuinfo.d("avg_progress_ratio"), 1));
cuinfo.put("progress_ratio" , m.nf(cuinfo.d("progress_ratio"), 1));

//출력
p.setLayout(ch);
p.setBody("mobile.classroom");
p.setVar("query", m.qs());

p.setLoop("list", list);
p.setVar("cuinfo", cuinfo);

p.setVar("prev_block", isPrev);
p.setVar("prev", prev);
p.display();

%>