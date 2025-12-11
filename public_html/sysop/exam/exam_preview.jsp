<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!Menu.accessible(72, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//아이디
int id = m.ri("id");
if(id == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
ExamDao exam = new ExamDao();
QuestionDao question = new QuestionDao();
QuestionCategoryDao category = new QuestionCategoryDao();

//카테고리
DataSet categories = category.getList(siteId);

//정보
DataSet info = exam.find("id = " + id + " AND status = 1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

//쿼리-난이도별
Vector<String> v = new Vector<String>();
DataSet grades = m.arr2loop(question.grades);
String rangeIdx = "'" + m.join("','" , info.s("range_idx").split(",")) + "'";
while(grades.next()) {
	if(info.i("mcnt" + grades.i("id")) > 0) {
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
	if(info.i("tcnt" + grades.i("id")) > 0) {
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

DataSet list = question.query(
	"SELECT a.*"
	+ " FROM (" + m.join(" UNION ALL ", v.toArray()) + ") a "
);

while(list.next()) {
	boolean isAuto = list.i("question_type") <= 3;
	list.put("score", info.i("assign" + list.i("grade")));
	list.put("ox_block", isAuto);
	list.put("ans_block", list.i("question_type") == 3 || list.i("question_type") == 4);
	list.put("choice_block", list.i("question_type") <= 2);
	list.put("textarea_block", list.i("question_type") == 4);
	list.put("input_type", list.i("question_type") == 1 ? "radio" : (list.i("question_type") == 2 ? "checkbox" : "text"));
	list.put("question_type", m.getItem(list.s("question_type"), question.types));
	list.put("grade", m.getItem(list.s("grade"), question.grades));
	list.put("question_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(list.s("question_file")));
	list.put("question_text", list.s("question_text").trim());

	list.put("cate_name", category.getTreeNames(list.i("category_id")));


	Vector<Hashtable<String, Object>> items = new Vector<Hashtable<String, Object>>();
	String answer = "||" + list.s("answer").trim() + "||";
	int collect = 0;
	for(int i=1; i<=list.i("item_cnt"); i++) {
		Hashtable<String, Object> map = new Hashtable<String, Object>();
		map.put("id", i);
		map.put("name", list.s("item" + i));
		map.put("file", !"".equals(list.s("item" + i + "_file")) ? (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(list.s("item" + i + "_file")) : "");

		map.put("is_answer", "");
		map.put("is_answer_txt", "");
		if(answer.indexOf("||" + i + "||") != -1) {
			map.put("is_answer", "style=\"font-weight:normal;color:red\"");
			map.put("is_answer_txt", "<font style=\"font-weight:normal;\"> [정답]</font>");
		}
		items.add(map);
	}

	//문항섞기
	if("Y".equals(info.s("shuffle_yn"))) Collections.shuffle(items);

	DataSet answers = new DataSet();
	for(int i=1; i<=items.size(); i++) {
		answers.addRow(items.get(i - 1));
	}

	list.put(".subLoop", answers);
}

//출력
p.setLayout("pop");
p.setBody("exam.exam_preview");
p.setVar("p_title", "평가 미리보기");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("info", info);

p.display();

%>