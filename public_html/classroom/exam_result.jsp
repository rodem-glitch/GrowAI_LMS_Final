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
String whrPK = "exam_id = " + eid + " AND course_user_id = " + cuid + " AND exam_step = " + examStep + " AND confirm_yn = 'Y' AND submit_yn = 'Y'";

//정보-시험
DataSet info = courseModule.query(
	"SELECT a.*, e.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.status != -1 AND e.id = " + eid + " "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + courseId + " AND e.site_id = " + siteId + ""
	+ " AND a.result_yn = 'Y' AND e.onoff_type = 'N'"
);
if(!info.next()) { m.jsErrClose(_message.get("alert.common.nodata")); return; };

//포맷팅
boolean isReady = false; //대기
boolean isEnd = false; //완료
if("1".equals(info.s("apply_type"))) { //시작일
	info.put("start_date_conv", m.time(_message.get("format.datetime.dot"), info.s("start_date")));
	info.put("end_date_conv", m.time(_message.get("format.datetime.dot"), info.s("end_date")));

	// 왜: end_date를 99991231235959 같은 "아주 먼 미래"로 두는 환경에서는,
	//     diffDate("I") 내부에서 int 오버플로우가 나 종료로 잘못 판정되는 경우가 있습니다.
	//     그래서 yyyyMMddHHmmss 값을 숫자로 비교해 안전하게 판단합니다.
	long nowDateTime = m.parseLong(now);
	long startDateTime = m.parseLong(info.s("start_date"));
	long endDateTime = m.parseLong(info.s("end_date"));
	isReady = startDateTime > 0 && startDateTime > nowDateTime;
	isEnd = endDateTime > 0 && endDateTime < nowDateTime;
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + info.i("chapter") }));
	//if(info.i("chapter") > 0 && 0 == courseProgress.findCount("course_id = " + courseId + " AND chapter = " + info.i("chapter") + " AND complete_yn = 'Y'")) isReady = true;
	//if(info.i("chapter") > 0 && 0  > courseProgress.findCount("course_id = " + courseId + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;
	if(info.i("chapter") > 0 && courseProgress.getExamReadyFlag(cuid, courseId, info.i("chapter"))) isReady = true;
}

//정보-응시자
DataSet euinfo = examUser.find(whrPK);
if(!euinfo.next()) { m.jsErrClose(_message.get("alert.classroom.nodata_exam")); return ; }

//시험문제목록
ListManager lm = new ListManager(jndi);
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
	list.put("choice_block", list.i("question_type") <= 2);
	list.put("textarea_block", list.i("question_type") == 4);
	list.put("input_type", list.i("question_type") == 1 ? "radio" : (list.i("question_type") == 2 ? "checkbox" : "text"));
	list.put("score", info.i("assign" + list.s("grade")));
	list.put("question_type_conv", m.getValue(list.s("question_type"), question.typesMsg));
	list.put("grade", m.getItem(list.s("grade"), question.grades));

	list.put("file_url", m.getUploadUrl(list.s("question_file")));
	list.put("question_text", list.s("question_text").trim());
	list.put("description_conv", m.nl2br(list.s("description")));

	String answer = "||" + list.s("answer").trim() + "||";

	Vector<Hashtable<String, Object>> v = new Vector<Hashtable<String, Object>>();
	for(int i = 1; i <= list.i("item_cnt"); i++) {
		Hashtable<String, Object> map = new Hashtable<String, Object>();
		map.put("id", i);
		map.put("name", list.s("item" + i));
		map.put("file", !"".equals(list.s("item" + i + "_file")) ? m.getUploadUrl(list.s("item" + i + "_file")) : "");

		map.put("is_answer", "");
		map.put("is_answer_txt", "");
		if(answer.indexOf("||" + i + "||") != -1) {
			map.put("is_answer", "style=\"font-weight:normal;color:red\"");
			map.put("is_answer_txt", "<font style=\"font-weight:normal;\"> [" + _message.get("classroom.exam.answer") + "]</font>");
		}

		v.add(map);
	}
//	if("Y".equals(info.s("shuffle_yn"))) Collections.shuffle(v);

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
	+ ", b.answer ques_answer, b.question_type, b.grade "
	+ ", e.assign1, e.assign2, e.assign3, e.assign4, e.assign5, e.assign6"
	+ " FROM " + examResult.table + " a "
	+ " LEFT JOIN " + question.table + " b ON a.question_id = b.id"
	+ " LEFT JOIN " + exam.table + " e ON e.id = a.exam_id "
	+ " WHERE a.exam_id = " + eid + " AND a.exam_step = " + examStep + " "
	+ " AND a.course_user_id = " + cuid + " "
	+ " ORDER BY a.question_id ASC "
);
int noAnswer = 0;
for(int i = 1; answers.next(); i++) {
	if("".equals(answers.s("answer").trim())) noAnswer++;
	answers.put("bg", i == pg ? "style=\"background:#FEE9F1;\"" : "");
	answers.put("curr", i == pg ? "curr=\"Y\"" : "");
	answers.put("answer_conv", "".equals(answers.s("answer").trim()) ? "-" : m.cutString(answers.s("answer"), 4));
	boolean isAuto = answers.i("question_type") <= 3;
	boolean isCorrect = false;
	if("2".equals(answers.s("question_type"))) {
		String[] ans1 = answers.s("ques_answer").split("\\|\\|");
		String[] ans2 = answers.s("answer").split("\\|\\|");
		Arrays.sort(ans1);
		Arrays.sort(ans2);

		if(ans1.length == ans2.length) {
			isCorrect = true;
			for(int j=0, max=ans1.length; j<max; j++) {
				if(!ans1[j].equals(ans2[j])) { isCorrect = false; break; }
			}
		}
	} else if(!"4".equals(answers.s("question_type"))) {
		isCorrect = answers.s("ques_answer").equals(answers.s("answer"));
	}

	answers.put("assign_score", Malgn.nf(answers.d("assign" + answers.s("grade")), 1));
	if(answers.d("assign_score") == answers.d("score")) isCorrect = true;
	answers.put("scoring_type", isCorrect ? 1 : (isAuto ? 2 : 3));

	answers.put("collect_yn", isCorrect
		? "<font style=\"font-family:tahoma;font-weight:bold;font-size:18px;color:blue;\">O</font>"
		: (isAuto ? "<font style=\"font-family:tahoma;font-weight:bold;font-size:18px;color:red;\">X</font>" : "<font style=\"font-family:tahoma;font-weight:bold;font-size:18px;color:black;\">-</font>")
	);
	answers.put("score", answers.d("score"));
}

info.put("no_answer_cnt", noAnswer);
info.put("no_answer_block", noAnswer > 0);

//출력
p.setLayout("blank");
p.setBody("classroom.exam_result");
p.setVar("list_query", m.qs("id"));
p.setVar("page_query", m.qs("page"));

p.setVar("euinfo", euinfo);
p.setVar("info", info);
p.setLoop("answers", answers);

p.setLoop("list", list);

p.setVar("prev_page", pg - 1); p.setVar("exists_prev", pg - 1 > 0);
p.setVar("next_page", pg + (lm.getTotalNum() == pg ? 0 : 1));

if(pg == lm.getTotalNum()) {
	list.last();
	p.setVar("exists_next", "".equals(list.s("user_answer")));
} else {
	p.setVar("exists_next", pg + 1 <= lm.getTotalNum());
}

p.setVar("estep", examStep);
p.display();


%>
