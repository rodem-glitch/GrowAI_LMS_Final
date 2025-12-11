<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(32, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
QuestionDao question = new QuestionDao();
QuestionCategoryDao category = new QuestionCategoryDao();
UserDao user = new UserDao();
FileDao file = new FileDao();

//폼체크
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");
//f.addElement("category_nm", null, "hname:'카테고리', required:'Y'");
f.addElement("grade", 1, "hname:'난이도', required:'Y', option:'number'");
f.addElement("question_type", "1", "hname:'문제유형', required:'Y'");
f.addElement("question", null, "hname:'문제', required:'Y'");
f.addElement("question_text", null, "hname:'문제설명', allowiframe:'Y', allowhtml:'Y'");
f.addElement("item_cnt", 5, "hname:'답변 갯수', option:'number'");
f.addElement("description", null, "hname:'정답설명'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("status", 1, "hname:'사용여부', required:'Y'");
f.addElement("question_file", null, "hname:'문제파일', allow:'jpg|jpeg|gif|png'");
if(m.ri("item_cnt") > 1) {
	for(int i=1; i<=m.ri("item_cnt"); i++) {
		f.addElement("item" + i, null, "hname:'문항" + i + "', required:'Y'");
		f.addElement("item" + i + "_file", "", "hname:'문항파일" + i + "', allow:'jpg|jpeg|gif|png'");
	}
}

//등록
if(m.isPost() && f.validate()) {

	String questionText = f.get("question_text");
	//제한-이미지URI
	if(-1 < questionText.indexOf("<img") && -1 < questionText.indexOf("data:image/") && -1 < questionText.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}

	//제한-용량
	int bytes = questionText.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)");
		return;
	}

	boolean isFormSingle = "1".equals(f.get("question_type"));
	boolean isFormMulti = "2".equals(f.get("question_type"));
	boolean isFormShort = "3".equals(f.get("question_type"));
	boolean isFormLong = "4".equals(f.get("question_type"));

	boolean isFormChoice = isFormSingle || isFormMulti;
	boolean isFormWrite = isFormShort || isFormLong;

	int newId = question.getSequence();
	question.item("id", newId);
	question.item("site_id", siteId);
	question.item("category_id", f.get("category_id"));
	question.item("grade", f.getInt("grade"));
	question.item("question_type", f.get("question_type"));
	question.item("question", f.get("question"));
	question.item("question_text", questionText);

	if(null != f.getFileName("question_file")) {
		File f1 = f.saveFile("question_file");
		if(null != f1) question.item("question_file", f.getFileName("question_file"));
	}

	for(int i = 1; i <= 5; i++) {
		question.item("item" + i, "");
		question.item("item" + i + "_file", "");
		if(isFormChoice && i <= f.getInt("item_cnt")) {
			if(null != f.getFileName("item" + i + "_file")) {
				File f1 = f.saveFile("item" + i + "_file");
				if(null != f1) question.item("item" + i + "_file", f.getFileName("item" + i + "_file"));
			}
			question.item("item" + i, f.get("item" + i));
		}
	}
	question.item("item_cnt", isFormChoice ? f.getInt("item_cnt") : 1);
	question.item("answer"
		, isFormMulti ? m.join("||", f.getArr("answer")) : (
			isFormLong ? f.get("answer2") : f.get("answer")
		)
	);

	question.item("description", f.get("description"));
	question.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	question.item("reg_date", m.time("yyyyMMddHHmmss"));
	question.item("status", f.getInt("status"));

	if(!question.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//갱신
	file.updateTempFile(f.getInt("temp_id"), newId, "question");

	m.jsReplace("question.jsp?cid=" + f.get("category_id"), "parent");
	return;

}


DataSet list = new DataSet();
for(int i=1; i<=5; i++) { list.addRow(); list.put("idx", i); }

//목록-카테고리
DataSet categories = category.getList(siteId);
while(categories.next()) {
	categories.put("display_block", categories.i("manager_id") == -99 || !courseManagerBlock || (courseManagerBlock && categories.i("manager_id") == userId));
}

//출력
p.setBody("question.question_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setLoop("types", m.arr2loop(question.types));
p.setLoop("grades", m.arr2loop(question.grades));
p.setLoop("status_list", m.arr2loop(question.statusList));
p.setLoop("categories", categories);

p.setVar("temp_id", m.getRandInt(-2000000, 1990000));
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>