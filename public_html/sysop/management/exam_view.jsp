<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();
QuestionDao question = new QuestionDao();
QuestionCategoryDao questionCategory = new QuestionCategoryDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//정보
DataSet info = courseModule.query(
	"SELECT a.course_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score "
	+ ", e.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + courseId + " AND a.module_id = " + id + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("onoff_type_conv", m.getItem(info.s("onoff_type"), exam.onoffTypes));
info.put("online_block", "N".equals(info.s("onoff_type")));
if("1".equals(info.s("apply_type"))) { //기간
	info.put("start_date_conv", m.time("yyyy.MM.dd HH시 mm분", info.s("start_date")));
	info.put("end_date_conv", m.time("yyyy.MM.dd HH시 mm분", info.s("end_date")));

	info.put("apply_type_1", true);
	info.put("apply_type_2", false);
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? "학습시작 전" : info.i("chapter") + " 차시 학습 후");

	info.put("apply_type_1", false);
	info.put("apply_type_2", true);
}

//현황
DataSet stat = courseModule.query(
	"SELECT COUNT(*) u_cnt "
	+ ", SUM( CASE WHEN e.submit_yn = 'Y' THEN 1 ELSE 0 END ) s_cnt "
	+ ", SUM( CASE WHEN e.submit_yn = 'Y' AND e.confirm_yn = 'Y' THEN 1 ELSE 0 END ) c_cnt "
	+ ", SUM( CASE WHEN e.submit_yn = 'Y' AND e.confirm_yn = 'Y' THEN e.marking_score ELSE 0 END ) t_score "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " LEFT JOIN " + examUser.table + " e "
		+ " ON e.exam_id = " + id + " AND e.course_user_id = a.id AND e.status = 1 "
	+ " WHERE a.status IN (1,3) AND a.course_id = " + courseId + " "
);
if(!stat.next()) stat.addRow();
stat.put("join_rate", m.nf(stat.i("u_cnt") > 0 ? stat.d("s_cnt") / stat.i("u_cnt") * 100 : 0.0, 1));
stat.put("eva_rate", m.nf(stat.i("s_cnt") > 0 ? stat.d("c_cnt") / stat.i("s_cnt") * 100 : 0.0, 1));
stat.put("u_cnt_conv", m.nf(stat.i("u_cnt")));
stat.put("s_cnt_conv", m.nf(stat.i("s_cnt")));
stat.put("c_cnt_conv", m.nf(stat.i("c_cnt")));
stat.put("avg_score", m.nf(stat.i("c_cnt") > 0 ? stat.d("t_score") / stat.i("c_cnt") : 0.0, 1));

//문항
DataSet questions = new DataSet();
for(int i = 1; i <= question.grades.length; i++) {
	questions.addRow();
	questions.put("grade", m.getItem(i, question.grades));
	questions.put("mcnt", info.i("mcnt" + i));
	questions.put("tcnt", info.i("tcnt" + i));
	questions.put("score", (info.i("mcnt" + i) + info.i("tcnt" + i)) * info.i("assign" + i));
}

//문제카테고리
DataSet rangeList = new DataSet();
if(!"".equals(info.s("range_idx"))) {
	rangeList = questionCategory.find("id IN (" + info.s("range_idx") + ")");
	questionCategory.setData(rangeList);
	while(rangeList.next()) {
		rangeList.put("cate_name", questionCategory.getTreeNames(rangeList.i("id")));
	}
}

//출력
p.setBody("management.exam_view");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("exam", info);
p.setVar("stat", stat);
p.setLoop("questions", questions);
p.setLoop("range_list", rangeList);

p.display();

%>