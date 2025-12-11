<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(53, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
CourseModuleDao cm = new CourseModuleDao();
CourseUserDao cu = new CourseUserDao();
SurveyUserDao su = new SurveyUserDao();
SurveyDao survey = new SurveyDao();
SurveyItemDao si = new SurveyItemDao();
SurveyResultDao sr = new SurveyResultDao();
SurveyQuestionDao sq = new SurveyQuestionDao();

//정보검사
DataSet info = cm.query(
	"SELECT a.course_id, a.module_nm, a.assign_score cm_assign_score, a.start_day cm_start_day, a.period cm_period "
	+ " , b.course_nm, b.year, b.step, b.study_sdate, b.study_edate "
	+ " , e.content "
	+ " , (SELECT COUNT(*) u_cnt FROM " + cu.table + " WHERE course_id = a.course_id AND status IN (1,3)) u_cnt "
	+ " , (SELECT COUNT(*) s_cnt FROM " + su.table + " su INNER JOIN " + cu.table + " cu ON su.course_user_id = cu.id AND cu.status IN (1,3) WHERE su.survey_id = a.module_id AND su.course_id = a.course_id AND su.status = 1 ) s_cnt "
	+ " FROM " + cm.table + " a "
	+ " INNER JOIN " + course.table + " b ON b.id = a.course_id"
	+ " INNER JOIN " + survey.table + " e ON e.id = a.module_id AND e.site_id = " + siteId
	+ " WHERE a.status = 1 AND a.course_id = "+ courseId +" AND a.module = 'survey' AND a.module_id = " + id
);
if(!info.next()) { m.jsError("해당 정보를 찾을 수 없습니다."); return; }

info.put("s_cnt", info.i("s_cnt"));
info.put("survey_rate", m.nf(info.i("u_cnt") > 0 ? info.d("s_cnt") / info.i("u_cnt") * 100 : 0.0, 1));
info.put("u_cnt_conv", m.nf(info.i("u_cnt")));
info.put("s_cnt_conv", m.nf(info.i("s_cnt")));
info.put("start_date_conv", m.time("yyyy.MM.dd", info.s("study_sdate")));
info.put("end_date_conv", "20991231".equals(info.s("study_edate")) ? "상시" : m.time("yyyy.MM.dd", info.s("study_edate")));
info.put("period_str", info.i("cm_period") <= 0 ? "학습기간 전체" : "개강 후 " + info.i("cm_start_day") + " 일 후 부터 " + info.i("cm_period") + " 일 동안");

//설문항목
DataSet list = si.query(
	"SELECT a.id survey_item_id, a.sort, b.* "
	+ " FROM " + si.table + " a "
	+ " INNER JOIN " + sq.table + " b ON b.id = a.question_id "
	+ " WHERE a.status = 1 AND a.survey_id = " + info.i("survey_id")
	+ " ORDER BY a.sort ASC "
);
while(list.next()) {
	DataSet result = new DataSet();
	DataSet answers = new DataSet();
	list.put("choice_block", list.i("question_type") == 1);
	list.put("rows", 2);
	if(list.i("question_type") == 1) {

		result = sr.query(
			"SELECT a.answer, COUNT(*) cnt"
			+ " FROM " + sr.table + " a"
			+ " INNER JOIN " + cu.table + " b ON a.course_user_id = b.id AND b.status IN (1,3) AND b.course_id = " + info.i("course_id")
			+ " INNER JOIN " + su.table + " su ON a.survey_id = su.survey_id AND a.course_user_id = su.course_user_id AND su.status = 1"
			+ " WHERE a.status = 1 AND a.survey_id = " + info.i("survey_id") + " AND a.survey_item_id = " + list.i("survey_item_id")
			+ " AND (a.answer != '' OR a.answer IS NOT NULL)"
			+ " GROUP BY a.answer"
		);

		Hashtable<String, String> tmpCount = new Hashtable<String, String>();
		while(result.next()) {
			tmpCount.put(result.s("answer"), result.s("cnt"));
		}

		for(int i=1; i<=list.getInt("item_cnt"); i++) {
			answers.addRow();
			answers.put("id", i);
			answers.put("name", list.s("item" + i));
			answers.put("sel_cnt", tmpCount.containsKey(i+"") ? m.parseInt(tmpCount.get(i+"")) : 0);
			answers.put("sel_cnt_conv", m.nf(answers.i("sel_cnt")));
		}
	}
	list.put(".sub", answers);

}

//출력
p.setBody("management.survey_view");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("info", info);
p.setLoop("list", list);

p.display();

%>