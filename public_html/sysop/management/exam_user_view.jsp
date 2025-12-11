<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//기본키
int eid = m.ri("eid");
int cuid = m.ri("cuid");
if(eid == 0 || cuid == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//PDF
String type = m.rs("type");
if("pdf".equals(type)) {
	String url = webUrl + "/management/exam_user_view.jsp?eid=" + eid + "&cuid=" + cuid;
	String path = dataDir + "/tmp/" + m.getUniqId() + ".pdf";
	String cmd = "/usr/local/bin/wkhtmltopdf -s A4 "
			+ " --cookie MLMSKEY2014" + siteId + "7 " + m.getCookie("MLMS14" + siteId + "7")
			+ (siteId > 1 ? " --disable-smart-shrinking " : "")
			+ " " + url + " " + path;

	m.exec(cmd);
	m.output(path, null);
	m.delFile(path);
	return;
}

//객체
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();
QuestionDao question = new QuestionDao();
ExamResultDao examResult = new ExamResultDao();
CourseUserDao courseUser = new CourseUserDao();
CourseModuleDao courseModule = new CourseModuleDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

//변수
String whrPk = "";
boolean	printBlock = "print".equals(m.rs("mode"));

//평가응시자정보
DataSet euinfo = examUser.query(
	"SELECT a.course_user_id, a.course_id, a.confirm_yn, a.user_id, a.score eu_score, a.marking_score eu_marking_score, a.exam_step, a.reg_date exam_user_reg_date "
	+ ", c.course_nm, c.year, c.step "
	+ ", e.user_nm, f.module_nm, f.assign_score cm_assign_score "
	+ ", g.* "
	+ " FROM " + examUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " INNER JOIN " + user.table + "  e ON a.user_id = e.id " + (deptManagerBlock ? " AND e.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " INNER JOIN " + courseModule.table + " f ON a.exam_id = f.module_id AND a.course_id = f.course_id AND f.module = 'exam' "
	+ " INNER JOIN " + exam.table + " g ON a.exam_id = g.id "
	+ " WHERE a.exam_id = " + eid + " AND a.course_user_id = " + cuid + " "
);
if(!euinfo.next()) { m.jsErrClose("응시정보를 알수 없습니다."); return; }
euinfo.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", euinfo.s("reg_date")));
euinfo.put("exam_user_reg_date_conv", m.time("yyyy.MM.dd HH:mm", euinfo.s("exam_user_reg_date")));
user.maskInfo(euinfo);

//기록-개인정보조회
if("".equals(m.rs("mode")) && euinfo.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, euinfo.size(), "이러닝 운영", euinfo);

//채점여부
boolean isConfirm = "Y".equals(euinfo.s("confirm_yn"));

//점수저장
if(m.isPost() && f.validate()) {
	String[] ilist = f.getArr("question_id");
	double total = 0;
	for(int i=0; i<ilist.length; i++) {
		double score = m.parseDouble(f.getArr("score")[i]);
		examResult.item("score", score);
		examResult.update("exam_id = " + eid + " AND course_user_id = " + cuid + " AND exam_step = " + euinfo.i("exam_step") + " AND question_id = " + ilist[i] + "");
		total += score;
	}

	//총점 저장
	examUser.execute(
		"UPDATE " + examUser.table + " "
		+ " SET confirm_yn = 'Y' "
		+ ", score = " + Math.min(euinfo.d("cm_assign_score"), euinfo.d("cm_assign_score") * total / 100) + " "
		+ ", marking_score = " + Math.min(total, 100.0) + " "
		+ ", confirm_user_id = " + userId + " "
		+ ", confirm_date = '" + m.time("yyyyMMddHHmmss") + "' "
		+ " WHERE exam_id = " + eid + " AND course_user_id = " + cuid + " AND exam_step = " + euinfo.i("exam_step") + " "
	);

	//점수 업데이트
	courseUser.setCourseUserScore(cuid, "exam");

	out.print("<script>alert('채점이 완료되었습니다.');opener.location.reload();window.close();</script>");
	return;
}

//평가문제목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum(1000);
lm.setTable(
	examResult.table + " a "
	+ " INNER JOIN " + question.table + " b ON a.question_id = b.id "
);
lm.setFields("a.question_id, a.answer user_answer, a.score, b.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.exam_id = " + eid + "");
lm.addWhere("a.exam_step = " + euinfo.i("exam_step") + "");
lm.addWhere("a.course_user_id = " + cuid + "");
lm.addWhere("a.course_id = " + euinfo.i("course_id") + "");
lm.setOrderBy("a.question_id ASC");

//포맷팅
String[] typeList = question.types;
DataSet list = lm.getDataSet();
while(list.next()) {
	boolean isAuto = list.i("question_type") <= 3;
	list.put("ox_block", isAuto);
	list.put("ans_block", list.i("question_type") == 3);
	list.put("choice_block", list.i("question_type") <= 2);
	list.put("textarea_block", list.i("question_type") == 4);
	list.put("input_type", list.i("question_type") == 1 ? "radio" : (list.i("question_type") == 2 ? "checkbox" : "text"));
	list.put("assign_score", euinfo.i("assign" + list.s("grade")));
	list.put("question_file_url", m.getUploadUrl(list.s("question_file")));
	list.put("question_text", list.s("question_text").trim());
	list.put("description_conv", m.nl2br(list.s("description")));
	list.put("user_answer_conv", m.htmlToText(list.s("user_answer")));

	Vector<Hashtable<String, Object>> items = new Vector<Hashtable<String, Object>>();
	String answer = "||" + list.s("answer").trim() + "||";

	for(int i = 1; i <= list.i("item_cnt"); i++) {
		Hashtable<String, Object> tmp = new Hashtable<String, Object>();
		tmp.put("id", i + "");
		tmp.put("name", list.s("item" + i));
		tmp.put("file", !"".equals(list.s("item" + i + "_file")) ? m.getUploadUrl(list.s("item" + i + "_file")) : "");

		tmp.put("is_answer", "");
		tmp.put("is_answer_txt", "");
		if(answer.indexOf("||" + i + "||") != -1) {
			tmp.put("is_answer", "style=\"font-weight:normal;color:red\"");
			tmp.put("is_answer_txt", "<font style=\"font-weight:normal;\"> [정답]</font>");
		}
		items.add(tmp);
	}

	boolean isCorrect = false;
	if("2".equals(list.s("question_type"))) {
		String[] ans1 = list.s("answer").split("\\|\\|");
		String[] ans2 = list.s("user_answer").split("\\|\\|");
		Arrays.sort(ans1);
		Arrays.sort(ans2);

		if(ans1.length == ans2.length) {
			isCorrect = true;
			for(int i=0, max=ans1.length; i<max; i++) {
				if(!ans1[i].equals(ans2[i])) { isCorrect = false; break; }
			}
		}
	} else if(!"4".equals(list.s("question_type"))) {
		isCorrect = list.s("user_answer").equals(list.s("answer"));
	}


	list.put("collect_yn", isCorrect
		? "<font style=\"font-family:tahoma;font-weight:bold;font-size:18px;color:blue;\">O</font>"
		: (isAuto ? "<font style=\"font-family:tahoma;font-weight:bold;font-size:18px;color:red;\">X</font>" : "<font style=\"font-family:tahoma;font-weight:bold;font-size:18px;color:black;\">-</font>")
	);
	if(isConfirm) {
		list.put("score", list.d("score"));
	} else {
		list.put("score", isCorrect ? list.i("assign_score") : 0);
		if(!isCorrect && !isAuto) list.put("score", "");
	}

	//if("Y".equals(info.s("shuffle_yn"))) Collections.shuffle(items);

	DataSet answers = new DataSet();
	for(int i=1; i<=items.size(); i++) {
		answers.addRow(items.get(i - 1));
	}
	list.put("question_type_conv", m.getItem(list.s("question_type"), typeList));
	list.put("grade", m.getItem(list.s("grade"), question.grades));
	list.put(".subLoop", answers);
}

//출력
p.setLayout(!printBlock ? "pop" : "blank");
p.setBody("management.exam_user_view" + (!printBlock ? "" : "_div"));
p.setVar("p_title", "시험 평가");
p.setVar("query", m.qs());

p.setVar("euinfo", euinfo);
p.setLoop("list", list);

p.setVar("print_block", printBlock);
p.display();

%>