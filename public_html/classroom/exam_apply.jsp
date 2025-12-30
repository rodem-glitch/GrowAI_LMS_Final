<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int eid = m.ri("eid");
if(eid == 0 || !m.encrypt("" + cuid + eid).equals(m.rs("ek"))) { m.jsErrClose(_message.get("alert.common.abnormal_access")); return; }

//폼입력
int examStep = m.ri("estep") > 0 ? m.ri("estep") : 1;

//객체
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();
CourseProgressDao courseProgress = new CourseProgressDao();

QuestionDao question = new QuestionDao();
ExamResultDao examResult = new ExamResultDao();

//변수
String whrPK = "exam_id = " + eid + " AND course_user_id = " + cuid + " AND exam_step = " + examStep + "";

//정보-시험
DataSet info = courseModule.query(
	"SELECT a.*, e.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.status != -1 AND e.id = " + eid + " "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + courseId + " AND e.site_id = " + siteId + ""
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; };

//포맷팅
boolean isReady = false; //대기
boolean isEnd = false; //완료
boolean isPeriodApply = "1".equals(info.s("apply_type"));
if("1".equals(info.s("apply_type"))) { //시작일
	info.put("start_date_conv", m.time(_message.get("format.datetime.dot"), info.s("start_date")));
	info.put("end_date_conv", m.time(_message.get("format.datetime.dot"), info.s("end_date")));

	// 왜: end_date를 99991231235959 같은 "아주 먼 미래"로 두는 환경에서는,
	//     diffDate("S") 내부에서 int 오버플로우가 나 종료로 잘못 판정되는 경우가 있습니다.
	//     그래서 yyyyMMddHHmmss 값을 숫자로 비교해 안전하게 판단합니다.
	long nowDateTime = m.parseLong(now);
	long startDateTime = m.parseLong(info.s("start_date"));
	long endDateTime = m.parseLong(info.s("end_date"));
	isReady = startDateTime > 0 && startDateTime > nowDateTime;
	isEnd = endDateTime > 0 && endDateTime < nowDateTime;

} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + info.i("chapter") }));
	//if(info.i("chapter") > 0 && info.i("chapter") > courseProgress.findCount("course_id = " + courseId + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;
	if(info.i("chapter") > 0 && courseProgress.getExamReadyFlag(cuid, courseId, info.i("chapter"))) isReady = true;

}

//제한-응시기간
// 왜: 학기(progress)가 종료(E)라도, 기간(apply_type=1)형 시험은 종료일 전까지 응시를 허용합니다.
boolean canOpenByProgress = "I".equals(progress) || ("E".equals(progress) && isPeriodApply);
if(isReady || isEnd || !canOpenByProgress) { m.jsErrClose(_message.get("alert.classroom.noperiod_exam")); return; }

//응시자 생성
if(0 == examUser.findCount(whrPK)) {

	examUser.item("exam_id", eid);
	examUser.item("course_user_id", cuid);
	examUser.item("exam_step", examStep);
	examUser.item("course_id", courseId);
	examUser.item("user_id", userId);
	examUser.item("site_id", siteId);
	examUser.item("choice_yn", "Y");
	examUser.item("score", 0);
	examUser.item("marking_score", 0);
	examUser.item("feedback", "");
	examUser.item("duration", 0);
	examUser.item("ba_cnt", 0);
	// 왜: `blur_cnt`가 NULL/빈값이면 응시 화면 템플릿의 JS가 깨져(문항 이동/제출 버튼이 안 눌리는 현상)
	// 부정행위(창 이탈) 카운팅 자체가 동작하지 않을 수 있어서, 최초 생성 시 0으로 고정합니다.
	examUser.item("blur_cnt", 0);
	examUser.item("submit_yn", "N");
	examUser.item("confirm_yn", "N");
	examUser.item("confirm_date", "");
	examUser.item("submit_date", "");
	examUser.item("apply_date", now);
	examUser.item("onload_date", "");
	examUser.item("unload_date", "");
	examUser.item("ip_addr", userIp);
	examUser.item("mod_date", now);
	examUser.item("reg_date", now);
	examUser.item("status", 0);
	if(!examUser.insert()) { m.jsErrClose(_message.get("alert.common.error_insert")); return; }

}

//정보-응시자
DataSet euinfo = examUser.find(whrPK);
if(!euinfo.next()) { m.jsErrClose(_message.get("alert.classroom.nodata_exam")); return ; }

//갱신-최초응시시간
if("".equals(euinfo.s("apply_date"))) {
	if(-1 == examUser.execute("UPDATE " + examUser.table + " SET apply_date = '" + now + "' WHERE " + whrPK)) {
		m.jsErrClose(_message.get("alert.classroom.error_exam")); return ;
	}
}

//시간정보
int unixNow = m.getUnixTime(now);
// 왜: `call_unload`(창 닫힘) 호출로 `unload_date`/`duration`이 갱신된 뒤 다시 들어오면,
// 기존 로직은 `onload_date` 기준으로 시간을 또 더해서(겹치는 구간이 2번 계산됨) 남은시간이 0으로 떨어질 수 있습니다.
// 그래서 실제로 마지막으로 기준이 되어야 하는 시간(대개 unload_date)을 우선 사용해 중복 누적을 막습니다.
int onloadUnix = !"".equals(euinfo.s("onload_date")) ? m.getUnixTime(euinfo.s("onload_date")) : 0;
int unloadUnix = !"".equals(euinfo.s("unload_date")) ? m.getUnixTime(euinfo.s("unload_date")) : 0;
int old = onloadUnix > 0 ? onloadUnix : unixNow;
if(unloadUnix > old) old = unloadUnix;
if(old == 0) old = unixNow;
int duration = Math.max(0, (unixNow - old - 2)) + euinfo.i("duration");
int remain = (info.i("exam_time") * 60) - duration;
if("1".equals(info.s("apply_type"))) { //시작일
	// 왜: m.getUnixTime()이 int 기반일 경우(레거시), 2038년 이후(예: 9999...) 날짜에서 오버플로우가 발생할 수 있습니다.
	//     이런 경우 기간 제한(eremain)이 0으로 떨어져 시험이 즉시 '종료'되는 부작용이 생기므로, 안전한 범위에서만 제한을 적용합니다.
	long endDateTime = m.parseLong(info.s("end_date"));
	if(endDateTime > 0 && endDateTime < 20380000000000L) {
		int unixEndDate = m.getUnixTime(m.addDate("I", -1, info.s("end_date"), "yyyyMMddHHmmss")); //1분전
		int eremain = unixEndDate > unixNow ? unixEndDate - unixNow : 0;
		if(remain > eremain) remain = eremain;
	}
} else if("2".equals(info.s("apply_type"))) { //차시
	
}
if(remain < 0) remain = 0;

//시험타이머 호출시(CALL)
if("call_retime".equals(m.rs("mode"))) {
	out.print("<script>");
	out.print("remain = " + remain + ";");
	out.print("</script>");
	return;
} else if("call_unload".equals(m.rs("mode"))) {
	// 왜: unload 이후 재접속 시 시간 누적이 꼬이지 않도록, 기준 시각(onload_date)도 함께 갱신합니다.
	examUser.execute("UPDATE " + examUser.table + " SET unload_date = '" + now + "', onload_date = '" + now + "', duration = " + duration + ", ba_cnt = " + m.ri("ba") + " WHERE " + whrPK);
	return;
} else if("call_blur".equals(m.rs("mode"))) {
	examUser.execute("UPDATE " + examUser.table + " SET blur_cnt = " + m.ri("blc") + " WHERE " + whrPK);
	return;
}

//갱신-시간관련정보
examUser.execute("UPDATE " + examUser.table + " SET onload_date = '" + now + "', unload_date = '', duration = " + duration + " WHERE " + whrPK);


//답안등록
if(m.isPost() && f.validate()) {

	//정보-시험결과
	//examResult.d(out);
	DataSet erinfo = examResult.find(whrPK + " AND question_id = " + f.getInt("question_id") + "");
	if(!erinfo.next()) { m.jsError(_message.get("alert.classroom.error_answer") + " [1]"); return; }

	String answer = m.join("||", f.getArr("answer" + f.getInt("question_id")));

	//제한-용량
	int bytes = answer.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsError(_message.get("alert.board.over_capacity", new String[] {"maximum=>60000", "bytes=>" + bytes}));
		return;
	}

	examResult.item("answer", answer);
	examResult.update(whrPK + " AND question_id = " + f.getInt("question_id") + "");


	if("Y".equals(f.get("submit_yn"))) {
		examUser.execute("UPDATE " + examUser.table + " SET submit_yn = 'Y', submit_date = '" + now + "', unload_date = '" + now + "', ip_addr = '" + userIp + "' WHERE " + whrPK);

		//자동채점-객관식만 있을 경우
		if("Y".equals(info.s("auto_complete_yn")) && (info.i("tcnt1") + info.i("tcnt2") + info.i("tcnt3") + info.i("tcnt4") + info.i("tcnt5") + info.i("tcnt6")) == 0) {
		//if("Y".equals(info.s("auto_complete_yn")) && (info.i("tcnt1") + info.i("tcnt2") + info.i("tcnt3") + info.i("tcnt4") + info.i("tcnt5")) == 0) {
			DataSet results = examResult.query(
				"SELECT a.question_id, a.answer user_answer, b.* "
				+ " FROM " + examResult.table + " a "
				+ " LEFT JOIN " + question.table + " b ON a.question_id = b.id "
				+ " WHERE  a.status = 1 AND a.course_user_id = " + cuid + " "
				+ " AND a.exam_id = " + eid + " AND a.exam_step = " + examStep + " "
				+ " ORDER BY a.question_id ASC "
			);
			double total = 0;
			while(results.next()) {
				//question_type : "1=>단일선택", "2=>다중선택", "3=>단답형", "4=>서술형"
				boolean isCorrect = false;
				if("2".equals(results.s("question_type"))) {
					String[] ans1 = results.s("answer").split("\\|\\|");
					String[] ans2 = results.s("user_answer").split("\\|\\|");
					Arrays.sort(ans1);
					Arrays.sort(ans2);
					if(ans1.length == ans2.length) {
						isCorrect = true;
						for(int i = 0; i < ans1.length; i++) {
							if(!ans1[i].equals(ans2[i])) { isCorrect = false; break; }
						}
					}
				} else if(!"4".equals(results.s("question_type"))) {
					isCorrect = results.s("user_answer").equals(results.s("answer"));
				}

				double assignScore = isCorrect ? info.d("assign" + results.s("grade")) : 0;

				examResult.execute(
					"UPDATE " + examResult.table + " SET "
					+ " score = " + assignScore + " "
					+ " WHERE " + whrPK + " AND question_id = " + results.i("question_id") + " "
				);
				total += assignScore;
			}

			//갱신-총점
			examUser.execute(
				"UPDATE " + examUser.table + " SET "
				+ " confirm_yn = 'Y' "
				+ ", score = " + Math.min(info.d("assign_score"), info.d("assign_score") * total / 100) + " "
				+ ", marking_score = " + Math.min(total, 100.0) + " "
				+ ", confirm_user_id = '" + userId + "' "
				+ ", confirm_date = '" + now + "' "
				+ " WHERE " + whrPK
			);

			//점수 업데이트
			courseUser.updateScore(cuid, "exam");
			courseUser.closeUser(cuid, userId);
		}

		out.print("<script>");
		out.print("alert('" + _message.get("classroom.module.submit") + "');");
		out.print("try { opener.location.href = opener.location.href; } catch(e) {}");
		out.print("window.close();");
		out.print("</script>");
	} else {
		m.jsReplace("exam_apply.jsp?" + m.qs());
	}
	return;
}

//응시여부 검사
if(euinfo.b("submit_yn") || euinfo.b("confirm_yn")) { m.jsErrClose(_message.get("alert.classroom.applied_exam")); return; }

//첫 응시인 경우 exam_result(문제) 등록
if(euinfo.i("status") == 0) {

	//기존출제삭제
	examResult.execute("DELETE FROM " + examResult.table + " WHERE " + whrPK);

	//난이도별 문제 추출
	int totalCnt = 0;
	DataSet grades = m.arr2loop(question.grades);

	Vector<String> v = new Vector<String>();
	String rangeIdx = "'" + m.join("','" , info.s("range_idx").split(",")) + "'";
	while(grades.next()) {
		totalCnt += info.getInt("mcnt" + grades.i("id"));
		totalCnt += info.getInt("tcnt" + grades.i("id"));

		if(info.getInt("mcnt" + grades.i("id")) > 0) {
			v.add(
				"SELECT * FROM " + question.table + " WHERE id IN ( SELECT ua.id FROM ( "
				+ question.randomQuery(
					"SELECT id FROM " + question.table + " "
					+ " WHERE status = 1 AND site_id = " + siteId + " "
					+ " AND category_id IN (" + rangeIdx + ") "
					+ " AND grade = " + grades.i("id") + " AND question_type IN ('1','2') "
					, info.i("mcnt" + grades.i("id"))
				) + " ) ua ) "
			);
		}
		if(info.getInt("tcnt" + grades.i("id")) > 0) {
			v.add(
				"SELECT * FROM " + question.table + " WHERE id IN ( SELECT ua.id FROM ( "
				+ question.randomQuery(
					"SELECT * FROM " + question.table + " "
					+ " WHERE status = 1 AND site_id = " + siteId + " "
					+ " AND category_id IN (" + rangeIdx + ") "
					+ " AND grade = " + grades.i("id") + " AND question_type IN ('3','4') "
					, info.i("tcnt" + grades.i("id"))
				) + " ) ua ) "
			);
		}
	}

	DataSet qlist = question.query(
		"SELECT ru.* "
		+ " FROM (" + m.join(" UNION ALL ", v.toArray()) + ") ru "
		+ " ORDER BY ru.category_id ASC, ru.id ASC "
	);

	while(qlist.next()) {
		examResult.item("exam_id", eid);
		examResult.item("exam_step", examStep);
		examResult.item("question_id", qlist.i("id"));
		examResult.item("course_user_id", cuid);
		examResult.item("course_id", courseId);
		examResult.item("site_id", siteId);
		examResult.item("score", 0);
		examResult.item("user_id", userId);
		examResult.item("answer", "");
		examResult.item("reg_date", now);
		examResult.item("status", 1);
		examResult.insert();
	}

	//목록-출제된문항
	DataSet questions = examResult.query(
		"SELECT b.grade "
		+ " FROM " + examResult.table + " a "
		+ " INNER JOIN " + question.table + " b ON a.question_id = b.id "
		+ " WHERE a.status = 1 AND a.course_user_id = " + cuid + " "
		+ " AND a.exam_id = " + eid + " AND a.exam_step = " + examStep + " "
	);
	int assignCnt = questions.size();
	int assignScore = 0;
	while(questions.next()) {
		assignScore += info.i("assign" + questions.s("grade"));
	}

	//제한-문항갯수및점수
	if(totalCnt != assignCnt || 100 != assignScore) {
		m.jsErrClose(_message.get("alert.classroom.error_question"));
		return;
	}

	//처리-출제완료
	examUser.execute("UPDATE " + examUser.table + " SET status = 1 WHERE " + whrPK);
}

//시험문제목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(1);
lm.setTable(
	examResult.table + " a "
	+ " LEFT JOIN " + question.table + " b ON a.question_id = b.id"
);
lm.setFields("a.question_id, a.answer user_answer, b.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.exam_id = " + eid + "");
lm.addWhere("a.exam_step = " + examStep + "");
lm.addWhere("a.course_id = " + courseId + "");
lm.addWhere("a.course_user_id = " + cuid + "");
lm.setOrderBy("a.question_id ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("choice_block", "1".equals(list.s("question_type")) || "2".equals(list.s("question_type")));
	list.put("textarea_block", "4".equals(list.s("question_type")));
	list.put("input_type", list.i("question_type") == 1 ? "radio" : (list.i("question_type") == 2 ? "checkbox" : "text"));
	list.put("score", info.i("assign" + list.s("grade")));
	list.put("question_type_conv", m.getValue(list.s("question_type"), question.typesMsg));
	list.put("grade", m.getValue(list.s("grade"), question.grades));

	list.put("file_url", m.getUploadUrl(list.s("question_file")));
	list.put("question_text", list.s("question_text").trim());
	list.put("question_content_block", !"".equals(list.s("question_file")) || !"".equals(list.s("question_text")));

	Vector<Hashtable<String, Object>> v = new Vector<Hashtable<String, Object>>();
	for(int i = 1; i <= list.i("item_cnt"); i++) {
		Hashtable<String, Object> map = new Hashtable<String, Object>();
		map.put("id", i);
		map.put("name", list.s("item" + i));
		map.put("file", !"".equals(list.s("item" + i + "_file")) ? m.getUploadUrl(list.s("item" + i + "_file")) : "");
		v.add(map);
	}
	if("Y".equals(info.s("shuffle_yn"))) Collections.shuffle(v);

	DataSet sub = new DataSet();
	for(int i = 1; i <= v.size(); i++) {
		sub.addRow(v.get(i - 1));
	}
	list.put(".sub", sub);
}

//페이지번호로 문제 이동처리
int pg = m.ri("page", 1);

//입력답안목록
DataSet answers = examResult.query(
	"SELECT a.* "
	+ " FROM " + examResult.table + " a "
	+ " WHERE a.exam_id = " + eid + " AND a.exam_step = " + examStep + " "
	+ " AND a.course_user_id = " + cuid + " "
	+ " ORDER BY a.question_id ASC "
);
int noAnswer = 0;
for(int i = 1; answers.next(); i++) {
	if("".equals(answers.s("answer").trim())) noAnswer++;
	answers.put("bg", i == pg ? "style=\"background:#FFF6ED;\"" : "");
	answers.put("curr", i == pg ? "curr=\"Y\"" : "");
	answers.put("answer_conv", "".equals(answers.s("answer").trim()) ? "-" : m.cutString(answers.s("answer"), 4));
}

info.put("no_answer_cnt", noAnswer);
info.put("no_answer_block", noAnswer > 0);

//출력
p.setLayout("blank");
p.setBody("classroom.exam_apply");
p.setVar("list_query", m.qs("id"));
p.setVar("page_query", m.qs("page"));

p.setVar("euinfo", euinfo);
p.setVar("info", info);
p.setLoop("answers", answers);

p.setLoop("list", list);

p.setVar("prev_page", pg - 1); p.setVar("exists_prev", pg - 1 > 0);
p.setVar("next_page", pg + (lm.getTotalNum() == pg ? 0 : 1));
p.setVar("remain", remain);

if(pg == lm.getTotalNum()) {
	list.last();
	p.setVar("exists_next", "".equals(list.s("user_answer")));
} else {
	p.setVar("exists_next", pg + 1 <= lm.getTotalNum());
}

p.setVar("estep", examStep);
p.display();

%>
