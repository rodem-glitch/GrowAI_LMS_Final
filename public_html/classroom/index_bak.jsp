<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ExamUserDao examUser = new ExamUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
ForumUserDao forumUser = new ForumUserDao();
SurveyUserDao surveyUser = new SurveyUserDao();

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


//도서목록
BookDao book = new BookDao();
CourseBookDao courseBook = new CourseBookDao();
DataSet books = courseBook.query(
	"SELECT b.*"
	+ " FROM " + courseBook.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
	+ " WHERE a.course_id = " + courseId + " "
);


//출력
p.setLayout(ch);
p.setBody("classroom.index");
p.setVar("query", m.qs());
p.setLoop("books", books);
p.setVar("cuinfo", cuinfo);

p.setVar("active_main", "select");
p.display();

%>