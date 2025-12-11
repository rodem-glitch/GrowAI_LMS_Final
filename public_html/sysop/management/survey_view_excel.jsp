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
		int total = 0;
		while(result.next()) {
			String[] tmpArr = m.split("||", result.s("answer"));
			for(int i = 0; i < tmpArr.length; i++) {
				tmpCount.put(tmpArr[i], (tmpCount.containsKey(tmpArr[i]) ? tmpCount.get(tmpArr[i]) : 0) + result.i("cnt"));
			}
			total += result.i("cnt");
		}

		for(int i = 1; i <= list.i("item_cnt"); i++) {
			answers.addRow();
			answers.put("id", i);
			answers.put("name", list.s("item" + i));
			answers.put("s_cnt", total);
			answers.put("sel_cnt", tmpCount.containsKey(i + "") ? tmpCount.get(i + "").intValue() : 0);
			answers.put("sel_cnt_conv", m.nf(answers.i("sel_cnt")));
			answers.put("percent", m.round(answers.d("sel_cnt") / answers.d("s_cnt") * 100, 2));
		}
	} else {
		result = surveyResult.query(
			"SELECT a.answer_text "
			+ " FROM " + surveyResult.table + " a "
			+ " INNER JOIN " + courseUser.table + " b ON "
				+ " a.course_user_id = b.id AND b.status IN (1,3) AND b.course_id = " + courseId + " "
			+ " INNER JOIN " + surveyUser.table + " su ON "
				+ " a.survey_id = su.survey_id AND a.course_user_id = su.course_user_id AND su.status = 1 "
			+ " INNER JOIN " + user.table + " u ON u.id = b.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
			+ " WHERE a.status = 1 AND a.survey_id = " + id + " AND a.survey_question_id = " + list.i("question_id") + " "
			+ " AND (a.answer != '' OR a.answer IS NOT NULL) "
		);
		int i = 1;
		while(result.next()) {
			answers.addRow();
			answers.put("id", i++);
			answers.put("answer", result.s("answer_text"));
		}
	}
	list.put(".sub", answers);

}

response.setHeader("Content-Disposition","attachment;filename=survey_result.xls");
response.setHeader("Content-Description", "JSP Generated Excel");
response.setContentType("application/vnd.ms-excel; charset=euc-kr");

//출력
p.setLayout(null);
p.setBody("management.survey_view_excel");
p.setLoop("list", list);
p.display();

%>