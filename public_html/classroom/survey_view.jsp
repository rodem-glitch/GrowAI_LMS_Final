<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
SurveyDao survey = new SurveyDao();
SurveyUserDao surveyUser = new SurveyUserDao();
SurveyCategoryDao surveyCategory = new SurveyCategoryDao();
CourseProgressDao courseProgress = new CourseProgressDao();

CourseSurveyDao courseSurvey = new CourseSurveyDao();

SurveyItemDao surveyItem = new SurveyItemDao();
SurveyResultDao surveyResult = new SurveyResultDao();
SurveyQuestionDao surveyQuestion = new SurveyQuestionDao();


//정보
DataSet info = courseModule.query(
	"SELECT a.*, s.category_id, s.survey_nm, s.content survey_content, s.item_cnt "
	+ ", u.user_id, u.score "
	+ ", c.category_nm "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module_id = s.id AND s.status = 1 AND s.id = " + id + " "
	+ " LEFT JOIN " + surveyCategory.table + " c ON s.category_id = c.id "
	+ " LEFT JOIN " + surveyUser.table + " u ON "
		+ "u.survey_id = a.module_id AND u.course_user_id = " + cuid + " "
	+ " WHERE a.status = 1 AND a.module = 'survey' "
	+ " AND a.course_id = " + courseId + " AND s.site_id = " + siteId + ""
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; };

//제한
//if(info.i("user_id") != 0) { m.jsError(_message.get("alert.classroom.applied_survey")); return; }

//포맷팅
boolean isReady = false; //대기
boolean isEnd = false; //완료
if("1".equals(info.s("apply_type"))) { //시작일
	info.put("start_date_conv", m.time(_message.get("format.datetime.dot"), info.s("start_date")));
	info.put("end_date_conv", m.time(_message.get("format.datetime.dot"), info.s("end_date")));

	isReady = 0 > m.diffDate("I", info.s("start_date"), now);
	isEnd = 0 < m.diffDate("I", info.s("end_date"), now);

	info.put("apply_type_1", true);
	info.put("apply_type_2", false);
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + info.i("chapter") }));
	if(info.i("chapter") > 0 && 0 == courseProgress.findCount("course_id = " + courseId + " AND chapter = " + info.i("chapter") + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;

	info.put("apply_type_1", false);
	info.put("apply_type_2", true);
}

String status = "-";
if(info.i("user_id") != 0) status = _message.get("classroom.module.status.submit");
else if("W".equals(progress) || isReady) status = _message.get("classroom.module.status.waiting");
else if("E".equals(progress) || isEnd) status = _message.get("classroom.module.status.end");
else status = "-";
info.put("status_conv", status);

info.put("reg_date_conv", info.i("user_id") != 0 ? m.time(_message.get("format.datetime.dot"), info.s("reg_date")) : _message.get("classroom.module.status.nosubmit"));
info.put("result_score", info.i("user_id") != 0 ? info.d("score") + _message.get("classroom.module.score") : "-" );

info.put("survey_content_conv", info.s("survey_content"));

//제한
boolean isOpen = !isReady && !isEnd && "I".equals(progress) && info.i("user_id") == 0;
info.put("open_block", isOpen);
//boolean isOpen = !isReady && !isEnd && "I".equals(progress);
//if(!isOpen) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//설문항목
DataSet list = surveyItem.query(
	"SELECT a.question_id, a.sort "
	+ " , q.* "
	+ " FROM " + surveyItem.table + " a "
	+ " INNER JOIN " + surveyQuestion.table + " q ON a.question_id = q.id AND q.status = 1 "
	+ " WHERE a.status = 1 AND a.survey_id = " + id + " AND q.site_id = " + siteId + " "
	+ " ORDER BY a.sort ASC "
);

//설문참여
if(m.isPost() && f.validate()) {

	if(!isOpen) { m.jsAlert(_message.get("alert.common.abnormal_access")); return; }

	//설문유저 등록
	surveyUser.item("survey_id", id);
	surveyUser.item("course_user_id", cuid);
	surveyUser.item("course_id", courseId);
	surveyUser.item("user_id", userId);
	surveyUser.item("site_id", siteId);
	surveyUser.item("score", 0);
	surveyUser.item("reg_date", m.time("yyyyMMddHHmmss"));
	surveyUser.item("status", 1);

	if(!surveyUser.insert()) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	//항목결과등록
	while(list.next()) {
		surveyResult.item("survey_id",  id);
		surveyResult.item("survey_question_id", list.i("question_id"));
		surveyResult.item("course_user_id", cuid);
		surveyResult.item("course_id", courseId);
		surveyResult.item("user_id", userId);
		surveyResult.item("site_id", siteId);

		if("1".equals(list.s("question_type"))) {
			surveyResult.item("answer", f.get("item" + list.i("question_id")));
			surveyResult.item("answer_text", "");
		} else if("M".equals(list.s("question_type"))) {
			surveyResult.item("answer", m.join("||", f.getArr("item" + list.i("question_id"))));
			surveyResult.item("answer_text", "");
		} else {
			surveyResult.item("answer", "");
			surveyResult.item("answer_text", f.get("item" + list.i("question_id")));
		}
		surveyResult.item("score", 0);
		surveyResult.item("reg_date", m.time("yyyyMMddHHmmss"));
		surveyResult.item("status", 1);

		if(!surveyResult.insert()) {
			m.jsAlert(_message.get("alert.common.error_insert"));
			return;
		}
	}

	//수료처리
	if(cinfo.b("assign_survey_yn")) courseUser.closeUser(cuid, userId);

	//이동
	m.jsReplace("survey.jsp?cuid=" + cuid, "parent");
	return;
}

//포맷팅
while(list.next()) {
	list.put("choice_block", "1".equals(list.s("question_type")) || "M".equals(list.s("question_type")));
	list.put("textarea_block", "3".equals(list.s("question_type")));
	list.put("input_type", "1".equals(list.s("question_type")) ? "radio" : ("M".equals(list.s("question_type")) ? "checkbox" : "text"));

	DataSet answers = new DataSet();
	for(int i = 1; i <= list.i("item_cnt"); i++) {
		answers.addRow();
		answers.put("id", i);
		answers.put("name", list.s("item" + i));
	}
	list.put(".sub", answers);

	//폼체크
	f.addElement("item" + list.s("question_id"), null, "hname:'Q" + list.i("sort") + "'" + (!"M".equals(list.s("question_type")) ? ", required:'Y'" : ""));
}

//출력
p.setLayout(ch);
p.setBody(ch + ".survey_view");
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("list", list);
p.display();

%>