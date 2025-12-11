<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(32, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
QuestionDao question = new QuestionDao();
QuestionCategoryDao category = new QuestionCategoryDao();

//카테고리
DataSet categories = category.getList(siteId);

//목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	question.table + " a "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
);
lm.setFields("a.*, c.category_nm");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(m.ri("qid") != 0) lm.addWhere("a.id = " + m.ri("qid") + "");
if(!"".equals(f.get("cid"))) {
	lm.addWhere("a.category_id IN (" + m.join(",", category.getChildNodes(f.get("cid"))) + ")");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	boolean isAuto = list.i("question_type") <= 3;
	list.put("ox_block", isAuto);
	list.put("ans_block", list.i("question_type") == 3 || list.i("question_type") == 4);
	list.put("choice_block", list.i("question_type") <= 2);
	list.put("textarea_block", list.i("question_type") == 4);
	list.put("input_type", list.i("question_type") == 1 ? "radio" : (list.i("question_type") == 2 ? "checkbox" : "text"));
	list.put("question_type", m.getItem(list.s("question_type"), question.types));
	list.put("grade", m.getItem(list.s("grade"), question.grades));

	list.put("question_text", list.s("question_text").trim());
	list.put("question_file_url", (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(list.s("question_file")));

	Vector<Hashtable<String, Object>> items = new Vector<Hashtable<String, Object>>();
	String answer = "||" + list.s("answer").trim() + "||";
	int collect = 0;
	for(int i = 1; i <= list.i("item_cnt"); i++) {
		Hashtable<String, Object> tmp = new Hashtable<String, Object>();
		tmp.put("id", i);
		tmp.put("name", list.s("item" + i));
		tmp.put("file", !"".equals(list.s("item" + i + "_file")) ? (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(list.s("item" + i + "_file")) : "");

		tmp.put("is_answer", "");
		tmp.put("is_answer_txt", "");
		if(answer.indexOf("||" + i + "||") != -1) {
			tmp.put("is_answer", "style=\"font-weight:normal;color:red\"");
			tmp.put("is_answer_txt", "<font style=\"font-weight:normal;\"> [정답]</font>");
		}
		items.add(tmp);
	}

	DataSet answers = new DataSet();
	for(int i = 1; i <= items.size(); i++) {
		answers.addRow(items.get(i-1));
	}

	list.put(".subLoop", answers);
}

//출력
p.setLayout("pop");
p.setBody("question.question_preview");
p.setVar("p_title", "문제 미리보기");

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
if(m.ri("qid") == 0) p.setVar("pagebar", lm.getPaging());

p.display();

%>