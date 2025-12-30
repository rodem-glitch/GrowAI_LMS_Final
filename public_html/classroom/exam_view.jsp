<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();
CourseProgressDao courseProgress = new CourseProgressDao();

//정보
DataSet info = courseModule.query(
	"SELECT a.*, e.exam_nm, e.exam_time, e.question_cnt, e.onoff_type, e.content "
	+ ", u.user_id, u.submit_yn, u.score, u.marking_score, u.submit_date, u.confirm_yn "
	+ ", u.apply_cnt"
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.status != -1 AND e.id = " + id + " "
	+ " LEFT JOIN " + examUser.table + " u ON "
		+ "u.exam_id = a.module_id AND u.course_user_id = " + cuid + " AND u.exam_step = 1 "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + courseId + " AND e.site_id = " + siteId + ""
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; };

//포맷팅
boolean isReady = false; //대기
boolean isEnd = false; //완료
boolean isPeriodApply = "1".equals(info.s("apply_type"));
if("1".equals(info.s("apply_type"))) { //기간
	info.put("start_date_conv", m.time(_message.get("format.datetime.dot"), info.s("start_date")));
	info.put("end_date_conv",
		info.s("start_date").substring(0, 8).equals(info.s("end_date").substring(0, 8))
		? m.time("HH:mm", info.s("end_date"))
		: m.time(_message.get("format.datetime.dot"), info.s("end_date"))
	);

	// 왜: end_date를 99991231235959 같은 "아주 먼 미래"로 두는 환경에서는,
	//     diffDate("S") 내부에서 int 오버플로우가 나 종료로 잘못 판정되는 경우가 있습니다.
	//     그래서 yyyyMMddHHmmss 값을 숫자로 비교해 안전하게 판단합니다.
	long nowDateTime = m.parseLong(now);
	long startDateTime = m.parseLong(info.s("start_date"));
	long endDateTime = m.parseLong(info.s("end_date"));
	isReady = startDateTime > 0 && startDateTime > nowDateTime;
	isEnd = endDateTime > 0 && endDateTime < nowDateTime;

	info.put("apply_type_1", true);
	info.put("apply_type_2", false);
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + info.i("chapter") }));
	//if(info.i("chapter") > 0 && info.i("chapter") > courseProgress.findCount("course_id = " + courseId + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;
	if(info.i("chapter") > 0 && courseProgress.getExamReadyFlag(cuid, courseId, info.i("chapter"))) isReady = true;

	info.put("apply_type_1", false);
	info.put("apply_type_2", true);
}

String status = "-";
if(info.b("submit_yn")) status = _message.get("classroom.exam.status.complete");
else if("W".equals(progress) || isReady) status = _message.get("classroom.module.status.waiting");
// 왜: 학기(progress)가 종료(E)라도, 기간(apply_type=1)형 시험은 종료일이 지나기 전까지는 응시를 허용해야 합니다.
//     (단, 차시(apply_type=2)형은 학기 종료와 함께 종료로 처리합니다.)
else if(isEnd || ("E".equals(progress) && !isPeriodApply)) status = _message.get("classroom.module.status.end");
else if("I".equals(progress) && info.i("user_id") != 0) status = _message.get("classroom.exam.status.during");
else status = "-";
info.put("status_conv", status);

info.put("offline_block", "F".equals(info.s("onoff_type")));
info.put("submit_date", !"".equals(info.s("submit_date")) ? m.time(_message.get("format.date.dot"), info.s("submit_date")) : _message.get("classroom.exam.status.absence"));
info.put("result_score", info.b("submit_yn")
		? (info.b("confirm_yn") ? info.d("marking_score") + _message.get("classroom.module.score") + " (" + info.d("score") + _message.get("classroom.module.score") + ")" : _message.get("classroom.module.status.evaluating"))
		: "-"
);

// 왜: 학기(progress)가 종료(E)라도, 기간(apply_type=1)형 시험은 종료일 전까지 입장을 허용합니다.
boolean canOpenByProgress = "I".equals(progress) || ("E".equals(progress) && isPeriodApply);
info.put("open_block",
	!isReady && !isEnd
	&& canOpenByProgress
	&& !info.b("confirm_yn") && !info.b("submit_yn")
	&& "N".equals(info.s("onoff_type"))
);
info.put("content_conv", m.nl2br(info.s("content")));

//재시험 여부 검사
info.put("retry_block", false);
if(!isReady && !isEnd
	&& canOpenByProgress
	&& info.b("confirm_yn")
	&& info.b("submit_yn")
	&& "N".equals(info.s("onoff_type"))
	&& info.b("retry_yn")
	&& info.d("marking_score") < info.d("retry_score")
	&& info.i("apply_cnt") <= info.i("retry_cnt")
) {
	info.put("retry_block", true);
}

//시험결과보기
info.put("result_block", false);
if(!"".equals(info.s("user_id"))
	&& info.b("confirm_yn")
	&& info.b("submit_yn")
	&& "N".equals(info.s("onoff_type"))
	&& !info.b("retry_block")
	&& info.b("result_yn")
) {
	info.put("result_block", true);
}

//목록-시험범위


//출력
p.setLayout(ch);
p.setBody("classroom.exam_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));

p.setVar(info);
p.setVar("ek", m.encrypt("" + cuid + id));
p.display();
%>
