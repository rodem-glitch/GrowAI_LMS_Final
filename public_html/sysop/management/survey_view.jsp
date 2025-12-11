<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
SurveyUserDao surveyUser = new SurveyUserDao();
SurveyDao survey = new SurveyDao();
SurveyItemDao surveyItem = new SurveyItemDao();
SurveyResultDao surveyResult = new SurveyResultDao();
SurveyQuestionDao surveyQuestion = new SurveyQuestionDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();


//정보
DataSet info = courseModule.query(
	"SELECT a.course_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score "
	+ ", s.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module_id = s.id "
	+ " WHERE a.status = 1 AND a.module = 'survey' "
	+ " AND a.course_id = " + courseId + " AND a.module_id = " + id + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
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
	+ ", SUM( CASE WHEN s.user_id != '' THEN 1 ELSE 0 END ) s_cnt "
	+ " FROM " + courseUser.table + " a "
	+ " LEFT JOIN " + surveyUser.table + " s "
		+ " ON s.survey_id = " + id + " AND s.course_user_id = a.id AND s.status = 1 "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.status IN (1,3) AND a.course_id = " + courseId + " "
);
if(!stat.next()) stat.addRow();
stat.put("survey_rate", m.nf(stat.i("u_cnt") > 0 ? stat.d("s_cnt") / stat.i("u_cnt") * 100 : 0.0, 1));
stat.put("u_cnt_conv", m.nf(stat.i("u_cnt")));
stat.put("s_cnt_conv", m.nf(stat.i("s_cnt")));


//설문항목
DataSet list = surveyItem.query(
	"SELECT a.question_id, a.sort, b.* "
	+ " FROM " + surveyItem.table + " a "
	+ " INNER JOIN " + surveyQuestion.table + " b ON a.question_id = b.id "
	+ " WHERE a.status = 1 AND a.survey_id = " + id + " "
	+ " ORDER BY a.sort ASC "
);

while(list.next()) {
	DataSet result = new DataSet();
	DataSet answers = new DataSet();
	list.put("type_conv", m.getItem(list.s("question_type"), surveyQuestion.types));
	list.put("choice_block", "1".equals(list.s("question_type")) || "M".equals(list.s("question_type")));
	list.put("rows", 2);
	if("1".equals(list.s("question_type")) || "M".equals(list.s("question_type"))) {

		result = surveyResult.query(
			"SELECT a.answer, COUNT(*) cnt "
			+ " FROM " + surveyResult.table + " a "
			+ " INNER JOIN " + courseUser.table + " b ON "
				+ " a.course_user_id = b.id AND b.status IN (1,3) AND b.course_id = " + courseId + " "
			+ " INNER JOIN " + surveyUser.table + " su ON "
				+ " a.survey_id = su.survey_id AND a.course_user_id = su.course_user_id AND su.status = 1 "
			+ " INNER JOIN " + user.table + " u ON u.id = b.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
			+ " WHERE a.status = 1 AND a.survey_id = " + id + " AND a.survey_question_id = " + list.i("question_id") + " "
			+ " AND (a.answer != '' OR a.answer IS NOT NULL) "
			+ " GROUP BY a.answer "
		);

		Hashtable<String, Integer> tmpCount = new Hashtable<String, Integer>();
		while(result.next()) {
			String[] tmpArr = m.split("||", result.s("answer"));
			for(int i = 0; i < tmpArr.length; i++) {
				tmpCount.put(tmpArr[i], (tmpCount.containsKey(tmpArr[i]) ? tmpCount.get(tmpArr[i]) : 0) + result.i("cnt"));
			}
		}

		for(int i = 1; i <= list.i("item_cnt"); i++) {
			answers.addRow();
			answers.put("id", i);
			answers.put("name", list.s("item" + i));
			answers.put("sel_cnt", tmpCount.containsKey(i + "") ? tmpCount.get(i + "").intValue() : 0);
			answers.put("sel_cnt_conv", m.nf(answers.i("sel_cnt")));
		}
	}
	list.put(".sub", answers);

}

//출력
p.setBody("management.survey_view");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("survey", info);
p.setVar("stat", stat);
p.setLoop("list", list);

p.setVar("masking_block", "Y".equals(SiteConfig.s("course_survey_masking_yn")));
p.display();

%>