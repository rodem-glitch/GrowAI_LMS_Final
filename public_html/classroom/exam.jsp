<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();
CourseProgressDao courseProgress = new CourseProgressDao();

//목록
DataSet list = courseModule.query(
	"SELECT a.*, e.exam_nm, e.onoff_type "
	+ ", u.user_id, u.submit_yn, u.score, u.marking_score, u.submit_date, u.confirm_yn "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.status != -1 "
	+ " LEFT JOIN " + examUser.table + " u ON "
		+ "u.exam_id = a.module_id AND u.course_user_id = " + cuid + " AND u.exam_step = 1 "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + courseId + " AND e.site_id = " + siteId + ""
	+ " ORDER BY a.start_date ASC, a.end_date ASC, a.period ASC, a.chapter ASC, a.module_id ASC "
);
while(list.next()) {
	list.put("exam_nm_conv", m.cutString(list.s("exam_nm"), 30));

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
		//if(list.i("chapter") > 0 && list.i("chapter") > courseProgress.findCount("course_id = " + courseId + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;
		if(list.i("chapter") > 0 && courseProgress.getExamReadyFlag(cuid, courseId, list.i("chapter"))) isReady = true;

		list.put("apply_type_1", false);
		list.put("apply_type_2", true);
	}

	String status = "-";
	if(list.b("submit_yn")) status = _message.get("classroom.exam.status.complete");
	else if("W".equals(progress) || isReady) status = _message.get("classroom.module.status.waiting");
	else if("E".equals(progress) || isEnd) status = _message.get("classroom.module.status.end");
	else if("I".equals(progress) && list.i("user_id") != 0) status = _message.get("classroom.exam.status.during");
	else status = "-";
	list.put("status_conv", status);

	list.put("open_block", "I".equals(progress));
	list.put("online_block", "N".equals(list.s("onoff_type")));

	list.put("submit_date_conv", !"".equals(list.s("submit_date")) ? m.time(_message.get("format.date.dot"), list.s("submit_date")) : "-");
	list.put("result_score", list.b("submit_yn")
			? (list.b("confirm_yn") ? list.d("marking_score") + _message.get("classroom.module.score") + "(" + list.d("score") + _message.get("classroom.module.score") + ")" : _message.get("classroom.module.status.evaluating"))
			: "-"
	);
}

//출력
p.setLayout(ch);
p.setBody("classroom.exam");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.display();

%>