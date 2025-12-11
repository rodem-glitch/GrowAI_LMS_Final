<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
int qid = m.ri("qid");
if(id == 0 || qid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
SurveyUserDao surveyUser = new SurveyUserDao();
SurveyDao survey = new SurveyDao();
SurveyItemDao surveyItem = new SurveyItemDao();
SurveyResultDao surveyResult = new SurveyResultDao();
SurveyQuestionDao surveyQuestion = new SurveyQuestionDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

//정보
DataSet info = courseModule.query(
	" SELECT a.course_id, a.module_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score "
	+ ", s.*, i.sort, q.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + survey.table + " s ON a.module_id = s.id "
	+ " INNER JOIN " + surveyItem.table + " i ON i.survey_id = s.id AND i.question_id = " + qid + " "
	+ " INNER JOIN " + surveyQuestion.table + " q ON q.id = i.question_id AND q.site_id = " + siteId + " "
	+ " WHERE a.status = 1 AND a.module = 'survey' "
	+ " AND a.course_id = " + courseId + " AND a.module_id = " + id + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
if("1".equals(info.s("apply_type"))) { //기간
	info.put("start_date_conv", m.time("yyyy.MM.dd HH시 mm분", info.s("start_date")));
	info.put("end_date_conv", m.time("yyyy.MM.dd HH시 mm분", info.s("end_date")));

	info.put("apply_type_1", true);
	info.put("apply_type_2", false);
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? "학습시작 전" : info.i("chapter") + " 차시 학습 후");

	info.put("apply_type_1", false);
	info.put("apply_type_2", true);
}

//변수
boolean selectBlock = "1".equals(info.s("question_type")) || "M".equals(info.s("question_type"));

//문제
Hashtable<String, String> itemMap = new Hashtable<String, String>();
if(selectBlock) {
	for(int i = 1; i <= info.i("item_cnt"); i++) {
		itemMap.put("item" + i, info.s("item" + i));
	}
}

//현황
DataSet stat = courseModule.query(
	" SELECT COUNT(*) u_cnt "
	+ ", SUM( CASE WHEN s.user_id != '' THEN 1 ELSE 0 END ) s_cnt "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " LEFT JOIN " + surveyUser.table + " s "
		+ " ON s.survey_id = " + id + " AND s.course_user_id = a.id AND s.status = 1 "
	+ " WHERE a.status IN (1,3) AND a.course_id = " + courseId + " "
);
if(!stat.next()) stat.addRow();
stat.put("survey_rate", m.nf(stat.i("u_cnt") > 0 ? stat.d("s_cnt") / stat.i("u_cnt") * 100 : 0.0, 1));
stat.put("u_cnt_conv", m.nf(stat.i("u_cnt")));
stat.put("s_cnt_conv", m.nf(stat.i("s_cnt")));

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//변수
boolean maskingBlock = "Y".equals(SiteConfig.s("course_survey_masking_yn"));

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : (selectBlock ? 10 : 5));
lm.setTable(
	surveyResult.table + " a "
	+ " INNER JOIN " + courseUser.table + " b ON a.course_user_id = b.id AND b.status IN (1,3) AND b.course_id = " + courseId + " "
	+ " INNER JOIN " + surveyUser.table + " su ON a.survey_id = su.survey_id AND a.course_user_id = su.course_user_id AND su.status = 1 "
	+ " INNER JOIN " + user.table + " u ON u.id = b.user_id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " LEFT JOIN " + user.table + " c ON a.user_id = c.id "
);
lm.setFields("a.*, c.user_nm, c.login_id");
lm.addWhere("a.status = 1");
lm.addWhere("a.survey_id = " + id + "");
lm.addWhere("a.survey_question_id = " + qid + "");
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) lm.addSearch("a.answer_text" + (!maskingBlock ? ",c.user_nm,c.login_id" : ""), f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	if(selectBlock) {
		String[] tmpArr = m.split("||", list.s("answer"));
		for(int i = 0; i < tmpArr.length; i++) {
			tmpArr[i] = itemMap.containsKey("item" + tmpArr[i]) ? itemMap.get("item" + tmpArr[i]) : tmpArr[i];
		}
		list.put("answer_conv", m.join(", ", tmpArr));
	} else {
		list.put("answer_conv", m.nl2br(list.s("answer_text")));
	}
	list.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("reg_date")));
	
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "응답상세보기-과정" + cinfo.s("id") + "-설문" + info.s("module_id") + "-문항" + info.s("sort") + "(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list
		, !maskingBlock
			? new String[] { "__ord=>No", "user_nm=>회원명", "login_id=>회원아이디", "answer_conv=>답변", "reg_date_conv=>등록일시" }
			: new String[] { "__ord=>No", "answer_conv=>답변", "reg_date_conv=>등록일" }
	);
	ex.write();
	return;
}

//출력
p.setLayout("pop");
p.setBody("management.survey_result");
p.setVar("p_title", "응답상세보기");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("info", info);
p.setVar("stat", stat);
p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("text_block", !selectBlock);
p.setVar("masking_block", maskingBlock);
p.setVar("search_block", !selectBlock || !maskingBlock);
p.display();

%>