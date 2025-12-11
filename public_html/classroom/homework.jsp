<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
HomeworkDao homework = new HomeworkDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();
CourseProgressDao courseProgress = new CourseProgressDao();

//목록
DataSet list = courseModule.query(
	"SELECT a.*, h.homework_nm, h.onoff_type "
	+ ", u.user_id, u.submit_yn, u.score, u.marking_score, u.confirm_yn, u.mod_date "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + homework.table + " h ON a.module_id = h.id AND h.status != -1 "
	+ " LEFT JOIN " + homeworkUser.table + " u ON "
		+ "u.homework_id = a.module_id AND u.course_user_id = " + cuid + " "
	+ " WHERE a.status = 1 AND a.module = 'homework' "
	+ " AND a.course_id = " + courseId + " AND h.site_id = " + siteId + ""
);
while(list.next()) {
	list.put("homework_nm_conv", m.cutString(list.s("homework_nm"), 30));

	//상태 [progress] (W : 대기, E : 종료, I : 수강중, R : 복습중)
	boolean isReady = false; //대기
	boolean isEnd = false; //완료
	if("1".equals(list.s("apply_type"))) { //시작일
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
	if(list.b("submit_yn")) status = _message.get("classroom.module.status.submit");
	else if("W".equals(progress) || isReady) status = _message.get("classroom.module.status.waiting");
	else if("E".equals(progress) || isEnd) status = _message.get("classroom.module.status.end");
	else if("I".equals(progress) && list.i("user_id") != 0) status = _message.get("classroom.module.status.writing");
	else status = "-";
	list.put("status_conv", status);

	//list.put("open_block", true);
	list.put("open_block", !isReady && !isEnd && "I".equals(progress) && "N".equals(list.s("onoff_type")));

	list.put("mod_date_conv", list.b("submit_yn") ? m.time(_message.get("format.date.dot"), list.s("mod_date")) : "-");
	list.put("result_score", list.b("submit_yn")
			? (list.b("confirm_yn") ? list.d("marking_score") + _message.get("classroom.module.score") + "(" + list.d("score") + _message.get("classroom.module.score") + ")" : _message.get("classroom.module.status.evaluating"))
			: "-"
	);
}

//출력
p.setLayout(ch);
p.setBody("classroom.homework");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setLoop("list", list);
p.display();

%>