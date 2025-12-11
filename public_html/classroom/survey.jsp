<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
SurveyDao survey = new SurveyDao();
SurveyUserDao surveyUser = new SurveyUserDao();
CourseProgressDao courseProgress = new CourseProgressDao();

//목록
DataSet list = courseModule.query(
	"SELECT a.*, s.survey_nm "
	+ ", u.user_id, u.score, u.reg_date "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module_id = s.id AND s.status != -1 "
	+ " LEFT JOIN " + surveyUser.table + " u ON "
		+ "u.survey_id = a.module_id AND u.course_user_id = " + cuid + " "
	+ " WHERE a.status = 1 AND a.module = 'survey' "
	+ " AND a.course_id = " + courseId + " AND s.site_id = " + siteId + ""
);
while(list.next()) {
	//상태 [progress] (W : 대기, E : 종료, I : 수강중, R : 복습중)
	boolean isReady = false; //대기
	boolean isEnd = false; //완료
	if("1".equals(list.s("apply_type"))) { //기간
		list.put("start_date_conv", m.time(_message.get("format.datetime.dot"), list.s("start_date")));
		list.put("end_date_conv", m.time(_message.get("format.datetime.dot"), list.s("end_date")));

		isReady = 0 > m.diffDate("I", list.s("start_date"), now);
		isEnd = 0 < m.diffDate("I", list.s("end_date"), now);

		list.put("apply_type_1", true);
		list.put("apply_type_2", false);
	} else if("2".equals(list.s("apply_type"))) { //차시
		list.put("apply_conv", list.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + list.i("chapter") }));
		if(list.i("chapter") > 0 && 0 == courseProgress.findCount("course_id = " + courseId + " AND chapter = " + list.i("chapter") + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;

		list.put("apply_type_1", false);
		list.put("apply_type_2", true);
	}

	String status = "-";
	if(list.i("user_id") != 0) status = _message.get("classroom.module.status.submit");
	else if("W".equals(progress) || isReady) status = _message.get("classroom.module.status.waiting");
	else if("E".equals(progress) || isEnd) status = _message.get("classroom.module.status.end");
	else status = "-";
	list.put("status_conv", status);

	//list.put("open_block", "I".equals(progress) && list.i("user_id") == 0);
	list.put("open_block", !isReady && !isEnd && "I".equals(progress) && list.i("user_id") == 0);

	list.put("reg_date_conv", list.i("user_id") != 0 ? m.time(_message.get("format.date.dot"), list.s("reg_date")) : "-");
	list.put("result_score", list.i("user_id") != 0 ? list.d("score") + _message.get("classroom.module.score") : "-");
}


//출력
p.setLayout(ch);
p.setBody(ch + ".survey");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.display();

%>