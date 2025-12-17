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
CourseUserDao courseUser = new CourseUserDao();
ExamDao exam = new ExamDao();
HomeworkDao homework = new HomeworkDao();
ForumDao forum = new ForumDao();
SurveyDao survey = new SurveyDao();

//카테고리
DataSet categories = category.getList(siteId);

//변수
String today = m.time("yyyyMMdd");

//정보
DataSet cinfo = course.find(
	"id = " + cid + " AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
cinfo.put("cate_name", category.getTreeNames(cinfo.i("category_id")));
if("R".equals(cinfo.s("course_type"))) {
	cinfo.put("request_date", m.time("yyyy.MM.dd", cinfo.s("request_sdate")) + " - " + m.time("yyyy.MM.dd", cinfo.s("request_edate")));
	cinfo.put("study_date", m.time("yyyy.MM.dd", cinfo.s("study_sdate")) + " - " + m.time("yyyy.MM.dd", cinfo.s("study_edate")));
	cinfo.put("alltime_block", false);
} else if("A".equals(cinfo.s("course_type"))) {
	cinfo.put("request_date", "상시");
	cinfo.put("study_date", "상시");
	cinfo.put("alltime_block", true);
}
cinfo.put("period_conv", cinfo.b("period_yn") ? "학습기간 설정" : "-");
cinfo.put("lesson_order_conv", cinfo.b("lesson_order_yn") ? "순차학습" : "-");
cinfo.put("course_type_conv", m.getItem(cinfo.s("course_type"), course.types));
cinfo.put("onoff_type_conv", m.getItem(cinfo.s("onoff_type"), course.onoffTypes));
cinfo.put("status_conv", m.getItem(cinfo.s("status"), course.statusList));
cinfo.put("display_conv", cinfo.b("display_yn") ? "정상" : "숨김");
cinfo.put("user_cnt", courseUser.findCount("course_id = " + cid + " AND status != -1"));

//폼입력
f.addElement("assign_progress", cinfo.i("assign_progress"), "hname:'출석(진도) 배점비율', option:'number', required:'Y'");
f.addElement("assign_exam", cinfo.i("assign_exam"), "hname:'시험 배점비율', option:'number', required:'Y'");
f.addElement("assign_homework", cinfo.i("assign_homework"), "hname:'과제 배점비율', option:'number', required:'Y'");
f.addElement("assign_forum", cinfo.i("assign_forum"), "hname:'토론 배점비율', option:'number', required:'Y'");
f.addElement("assign_etc", cinfo.i("assign_etc"), "hname:'기타 배점비율', option:'number', required:'Y'");
f.addElement("pass_yn", cinfo.s("pass_yn"), "hname:'합격 상태 사용여부'");
f.addElement("limit_total_score", cinfo.i("limit_total_score"), "hname:'총점 수료기준', option:'number', required:'Y'");
f.addElement("limit_progress", cinfo.i("limit_progress"), "hname:'진도 수료기준', option:'number', required:'Y'");
f.addElement("limit_exam", cinfo.i("limit_exam"), "hname:'시험 수료기준', option:'number', required:'Y'");
f.addElement("limit_homework", cinfo.i("limit_homework"), "hname:'과제 수료기준', option:'number', required:'Y'");
f.addElement("limit_forum", cinfo.i("limit_forum"), "hname:'토론 수료기준', option:'number', required:'Y'");
f.addElement("limit_etc", cinfo.i("limit_etc"), "hname:'기타 수료기준', option:'number', required:'Y'");
f.addElement("complete_limit_progress", cinfo.i("complete_limit_progress"), "hname:'진도 수료(완료) 기준', option:'number', required:'Y'");
f.addElement("complete_limit_total_score", cinfo.i("complete_limit_total_score"), "hname:'총점 수료(완료) 기준', option:'number', required:'Y'");

//수정
if(m.isPost() && f.validate()) {

	// 왜: "합격 상태"를 사용하는 경우에만(=3단계 판정) 합격 기준(limit_*)이 의미가 있습니다.
	// 합격을 사용하지 않는 환경(=2단계 판정)에서는 수료(완료) 기준만으로 판정하므로,
	// 여기서 불필요하게 입력을 막지 않도록 합격 사용 시에만 비교 제한을 걸어줍니다.
	boolean usePass = "Y".equals(f.get("pass_yn", "N"));
	if(usePass) {
		if(f.getInt("complete_limit_progress") > f.getInt("limit_progress")) {
			m.jsAlert("수료(완료) 진도 기준은 합격 진도 기준을 넘을 수 없습니다."); return;
		}
		if(f.getInt("complete_limit_total_score") > f.getInt("limit_total_score")) {
			m.jsAlert("수료(완료) 총점 기준은 합격 총점 기준을 넘을 수 없습니다."); return;
		}
	}

	//과정
	course.item("assign_progress", f.getInt("assign_progress"));
	course.item("assign_exam", f.getInt("assign_exam"));
	course.item("assign_homework", f.getInt("assign_homework"));
	course.item("assign_forum", f.getInt("assign_forum"));
	course.item("assign_etc", f.getInt("assign_etc"));
	course.item("pass_yn", usePass ? "Y" : "N");
	course.item("limit_progress", f.getInt("limit_progress"));
	course.item("limit_exam", f.getInt("limit_exam"));
	course.item("limit_homework", f.getInt("limit_homework"));
	course.item("limit_forum", f.getInt("limit_forum"));
	course.item("limit_etc", f.getInt("limit_etc"));
	course.item("limit_total_score", f.getInt("limit_total_score"));
	course.item("complete_limit_progress", f.getInt("complete_limit_progress"));
	course.item("complete_limit_total_score", f.getInt("complete_limit_total_score"));
	if(!course.update("id = " + cid + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.jsAlert("성공적으로 수정했습니다.");
	m.jsReplace("course_evaluation.jsp?cid=" + cid, "parent");
	return;
}

//목록-시험
DataSet exams = courseModule.query(
	"SELECT a.*, e.exam_nm "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + cid + " AND e.site_id = " + siteId + ""
);
while(exams.next()) {
	if("1".equals(exams.s("apply_type"))) { //기간
		exams.put("start_date_conv", m.time("yyyy.MM.dd HH:mm", exams.s("start_date")));
		exams.put("end_date_conv", m.time("yyyy.MM.dd HH:mm", exams.s("end_date")));
		exams.put("apply_type_1", true);
		exams.put("apply_type_2", false);
	} else if("2".equals(exams.s("apply_type"))) { //차시
		exams.put("apply_conv", exams.i("chapter") == 0 ? "학습시작 전" : exams.i("chapter") + " 강의 학습 후");
		exams.put("apply_type_1", false);
		exams.put("apply_type_2", true);
	}
}

//목록-과제
DataSet homeworks = courseModule.query(
	"SELECT a.*, h.homework_nm "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id AND h.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'homework' "
	+ " AND a.course_id = " + cid + " AND h.site_id = " + siteId + ""
);
while(homeworks.next()) {
	if("1".equals(homeworks.s("apply_type"))) { //기간
		homeworks.put("start_date_conv", m.time("yyyy.MM.dd HH:mm", homeworks.s("start_date")));
		homeworks.put("end_date_conv", m.time("yyyy.MM.dd HH:mm", homeworks.s("end_date")));
		homeworks.put("apply_type_1", true);
		homeworks.put("apply_type_2", false);
	} else if("2".equals(homeworks.s("apply_type"))) { //차시
		homeworks.put("apply_conv", homeworks.i("chapter") == 0 ? "학습시작 전" : homeworks.i("chapter") + " 강의 학습 후");
		homeworks.put("apply_type_1", false);
		homeworks.put("apply_type_2", true);
	}
}

//목록-토론
DataSet forums = courseModule.query(
	"SELECT a.*, f.forum_nm "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + forum.table + " f ON a.module_id = f.id AND f.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'forum' "
	+ " AND a.course_id = " + cid + " AND f.site_id = " + siteId + ""
);
while(forums.next()) {
	if("1".equals(forums.s("apply_type"))) { //기간
		forums.put("start_date_conv", m.time("yyyy.MM.dd HH:mm", forums.s("start_date")));
		forums.put("end_date_conv", m.time("yyyy.MM.dd HH:mm", forums.s("end_date")));
		forums.put("apply_type_1", true);
		forums.put("apply_type_2", false);
	} else if("2".equals(forums.s("apply_type"))) { //차시
		forums.put("apply_conv", forums.i("chapter") == 0 ? "학습시작 전" : forums.i("chapter") + " 강의 학습 후");
		forums.put("apply_type_1", false);
		forums.put("apply_type_2", true);
	}
}

//목록-설문
DataSet surveys = courseModule.query(
	"SELECT a.*, s.survey_nm "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module_id = s.id AND s.status != -1 "
	+ " WHERE a.status = 1 AND a.module = 'survey' "
	+ " AND a.course_id = " + cid + " AND s.site_id = " + siteId + ""
);
while(surveys.next()) {
	if("1".equals(surveys.s("apply_type"))) { //기간
		surveys.put("start_date_conv", m.time("yyyy.MM.dd HH:mm", surveys.s("start_date")));
		surveys.put("end_date_conv", m.time("yyyy.MM.dd HH:mm", surveys.s("end_date")));
		surveys.put("apply_type_1", true);
		surveys.put("apply_type_2", false);
	} else if("2".equals(surveys.s("apply_type"))) { //차시
		surveys.put("apply_conv", surveys.i("chapter") == 0 ? "학습시작 전" : surveys.i("chapter") + " 강의 학습 후");
		surveys.put("apply_type_1", false);
		surveys.put("apply_type_2", true);
	}
}

//출력
p.setBody("course.course_evaluation");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("course", cinfo);
p.setLoop("exams", exams);
p.setLoop("homeworks", homeworks);
p.setLoop("forums", forums);
p.setLoop("surveys", surveys);

p.setVar("tab_evaluation", "current");
p.display();

%>
