<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(50, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int examId = m.ri("id");
if(examId == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
CourseModuleDao cm = new CourseModuleDao();
CourseLessonDao cl = new CourseLessonDao();
CourseUserDao cu = new CourseUserDao();
QuestionDao question = new QuestionDao();
ExamDao exam = new ExamDao();
ExamUserDao eu = new ExamUserDao();
LessonDao lesson = new LessonDao();

//정보검사
DataSet info = cm.query(
	"SELECT a.course_id, a.module_nm, a.assign_score cm_assign_score, a.start_day cm_start_day, a.period cm_period, b.course_nm, b.year, b.step, b.study_sdate, b.study_edate, d.*"
	+ " FROM " + cm.table + " a "
	+ " INNER JOIN " + course.table + " b ON a.course_id = b.id"
	+ " INNER JOIN " + exam.table + " d ON a.module_id = d.id"
	+ " WHERE a.status = 1 AND a.course_id = " + courseId + " AND a.module = 'exam' AND a.module_id = " + examId
);

if(!info.next()) { m.jsError("해당 정보를 찾을 수 없습니다."); return; }

DataSet cntInfo = cu.query(
	"SELECT COUNT(*) u_cnt"
	+ ", SUM(CASE WHEN b.submit_yn = 'Y' THEN 1 ELSE 0 END) s_cnt"
	+ ", SUM(CASE WHEN b.submit_yn = 'Y' AND b.confirm_yn = 'Y' THEN 1 ELSE 0 END) c_cnt"
	+ ", SUM(CASE WHEN b.submit_yn = 'Y' AND b.confirm_yn = 'Y' THEN b.marking_score ELSE 0 END) t_score"
	+ " FROM " + cu.table + " a"
	+ " LEFT JOIN " + eu.table + " b ON b.course_user_id = a.id AND b.status = 1 AND b.exam_id = " + info.i("module_id")
	+ " WHERE a.course_id = " + info.i("course_id") + " AND a.status IN (1,3)"
);
if(!cntInfo.next()) { cntInfo.addRow(); }
info.put("join_rate", m.nf(cntInfo.i("u_cnt") > 0 ? cntInfo.d("s_cnt") / cntInfo.i("u_cnt") * 100 : 0.0, 2));
info.put("eva_rate", m.nf(cntInfo.i("s_cnt") > 0 ? cntInfo.d("c_cnt") / cntInfo.i("s_cnt") * 100 : 0.0, 2));
info.put("u_cnt_conv", m.nf(cntInfo.i("u_cnt")));
info.put("s_cnt_conv", m.nf(cntInfo.i("s_cnt")));
info.put("c_cnt_conv", m.nf(cntInfo.i("c_cnt")));
info.put("avg_score", m.nf(cntInfo.i("c_cnt") > 0 ? cntInfo.d("t_score") / cntInfo.i("c_cnt") : 0.0, 2));
info.put("start_date_conv", m.time("yyyy.MM.dd", info.s("study_sdate")));
info.put("end_date_conv", "20991231".equals(info.s("study_edate")) ? "상시" : m.time("yyyy.MM.dd", info.s("study_edate")));
info.put("period_str", info.i("cm_period") <= 0 ? "학습기간 전체" : "개강 후 " + info.i("cm_start_day") + " 일 후 부터 " + info.i("cm_period") + " 일 동안");

DataSet quesItems = new DataSet();
for(int i=1, max=question.grades.length; i<=max; i++) {
	quesItems.addRow();
	quesItems.put("grade", m.getItem(i, question.grades));
	quesItems.put("mcnt", info.i("mcnt" + i));
	quesItems.put("tcnt", info.i("tcnt" + i));
	quesItems.put("score", (info.i("mcnt" + i) + info.i("tcnt" + i)) * info.i("assign" + i));
}

DataSet lessonList = cl.query(
	"SELECT a.*, b.subject, b.type"
	+ " FROM " + cl.table + " a "
	+ " INNER JOIN " + lesson.table + " b ON a.lesson_id = b.id "
	+ " WHERE a.status = 1 AND a.course_id = " + info.i("course_id")
	+ " AND a.lesson_id IN (" + m.join(",", info.s("range_idx").split(",")) + ")"
	+ " ORDER BY a.chapter ASC"
);
while(lessonList.next()) {
	lessonList.put("chapter_name", "[" + lessonList.i("chapter") + "차시] ");
	lessonList.put("subject_conv", m.cutString(lessonList.s("subject"), 42));
}

//출력
p.setBody("management.exam_view");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("info", info);
p.setLoop("ques_items", quesItems);
p.setLoop("lesson_list", lessonList);

p.display();

%>