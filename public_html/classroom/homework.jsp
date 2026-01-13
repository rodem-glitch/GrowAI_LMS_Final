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
	boolean isPeriodApply = "1".equals(list.s("apply_type"));
	if(isPeriodApply) { //기간
		list.put("start_date_conv", m.time(_message.get("format.datetime.dot"), list.s("start_date")));
		list.put("end_date_conv", m.time(_message.get("format.datetime.dot"), list.s("end_date")));

		// 왜: end_date를 99991231235959 같은 "아주 먼 미래"로 두는 환경에서는,
		//     diffDate("I") 내부에서 int 오버플로우가 나 종료로 잘못 판정되는 경우가 있습니다.
		//     그래서 yyyyMMddHHmmss 값을 숫자로 비교해 안전하게 판단합니다.
		long nowDateTime = m.parseLong(now);
		long startDateTime = m.parseLong(list.s("start_date"));
		long endDateTime = m.parseLong(list.s("end_date"));
		isReady = startDateTime > 0 && startDateTime > nowDateTime;
		isEnd = endDateTime > 0 && endDateTime < nowDateTime;

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
	// 왜: 기간형 과제(apply_type=1)는 "과제 기간"이 곧 제출 가능 조건이므로,
	//     수강상태(progress=W 대기)만으로 제출을 막으면 학사/매핑 과정에서 "항상 대기"가 되는 문제가 생길 수 있습니다.
	//     따라서 기간형은 isReady(과제 시작 전)만 대기로 처리하고, 차시형(apply_type=2)만 수강 대기(progress=W)를 반영합니다.
	else if(isReady || ("W".equals(progress) && !isPeriodApply)) status = _message.get("classroom.module.status.waiting");
	// 왜: 학기(progress)가 종료(E)라도, 기간(apply_type=1)형 과제는 종료일이 지나기 전까지는 제출을 허용해야 합니다.
	//     (단, 차시(apply_type=2)형은 학기 종료와 함께 종료로 처리합니다.)
	else if(isEnd || ("E".equals(progress) && !isPeriodApply)) status = _message.get("classroom.module.status.end");
	else if("I".equals(progress) && list.i("user_id") != 0) status = _message.get("classroom.module.status.writing");
	else status = "-";
	list.put("status_conv", status);

	//list.put("open_block", true);
	// 왜: 제출 폼 노출은 "과제 기간"을 최우선으로 봐야 합니다.
	// - 기간형(apply_type=1): 과제 기간 내면 수강 상태와 무관하게 제출 가능(학사/숨김 매핑 과정의 progress 이슈 방지)
	// - 차시형(apply_type=2): 수강중(I) 또는 복습중(R)일 때만 제출 가능
	boolean canOpenByProgress = isPeriodApply ? true : ("I".equals(progress) || "R".equals(progress));
	list.put("open_block", !isReady && !isEnd && canOpenByProgress && "N".equals(list.s("onoff_type")));

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
