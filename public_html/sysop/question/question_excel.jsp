<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.util.regex.Pattern" %><%@ include file="init.jsp" %><%

//접근권한
//if(!Menu.accessible(19, lessonId, lessonKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
QuestionDao question = new QuestionDao();
QuestionCategoryDao category = new QuestionCategoryDao();
UserDao user = new UserDao();

//폼체크
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("file", null, "hname:'파일', required:'Y', allow:'xls'");

//등록
if(m.isPost() && f.validate()) {

	String mode = f.get("mode");

	File excelFile = f.saveFile("file");
	if(excelFile == null) { m.jsAlert("엑셀업로드시에 오류가 발생했습니다."); return; }

	DataSet list = new DataSet();
	DataSet rs = new ExcelReader(excelFile.getAbsolutePath()).getDataSet();
	int lessonId = 0;
	int totalTime = 0;
	int totalPage = 0;
	int i = 1;
	while(rs.next()) {
		if(i++ < 2) continue;
		question.clear();

		int intType = 0;
		int itemCnt = 0;
		String type = rs.s("col1").trim();
		String quest = rs.s("col2").trim();
		String ans1 = rs.s("col3").trim();
		String ans2 = rs.s("col4").trim();
		String ans3 = rs.s("col5").trim();
		String ans4 = rs.s("col6").trim();
		String ans5 = rs.s("col7").trim();
		String answer = rs.s("col8").trim();
		String description = rs.s("col9").trim();
		int grade = 1;

		if(!"".equals(ans5)) itemCnt = 5;
		else if(!"".equals(ans4)) itemCnt = 4;
		else if(!"".equals(ans3)) itemCnt = 3;
		else if(!"".equals(ans2) && !"".equals(ans1)) itemCnt = 2;

		if("선다형".equals(type)) { intType = 1; }
		else if("단답형".equals(type)) { intType = 3; itemCnt = 1; }
		else if("서술형".equals(type)) { intType = 4; itemCnt = 1; }
		else continue;

		String gradeStr = rs.s("col0").trim().toUpperCase();
		if(Pattern.matches("[A-F]{1}", gradeStr)) grade = gradeStr.charAt(0) - 64;

		if(itemCnt == 0 || "".equals(quest) || "".equals(answer)) continue;

		question.item("site_id", siteId);
		question.item("category_id", f.getInt("category_id"));
		question.item("grade", grade);
		question.item("question_type", intType);
		int pos = quest.indexOf("\n");
		if(pos > -1) {
			question.item("question", quest.substring(0, pos));
			question.item("question_text", quest.substring(pos).trim());
		} else {
			question.item("question", quest);
			question.item("question_text", "");
		}
		question.item("item_cnt", itemCnt);
		question.item("item1", ans1);
		question.item("item2", ans2);
		question.item("item3", ans3);
		question.item("item4", ans4);
		question.item("item5", ans5);
		question.item("answer", answer);
		question.item("description", description);
		question.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
		question.item("reg_date", m.time());
		question.item("status", 1);

		if("reg".equals(mode)) {
			question.insert();
		} else {
			question.item("grade_conv", m.getItem(grade, question.grades));
			question.item("question_type_conv", m.getItem(intType, question.types));
			list.addRow(question.record);
		}
	}

	excelFile.delete();

	if("reg".equals(mode)) {
		m.jsAlert("성공적으로 등록되었습니다.");
		m.jsReplace("question_list.jsp", "parent");
	} else {
		p.setLayout("blank");
		p.setBody("question.question_excel_view");
		p.setVar("total_cnt", list.size());
		p.setLoop("list", list);
		p.display();
	}
	return;
}

//목록-카테고리
DataSet categories = category.getList(siteId);
while(categories.next()) {
	categories.put("display_block", categories.i("manager_id") == -99 || !courseManagerBlock || (courseManagerBlock && categories.i("manager_id") == userId));
}

//출력
p.setLayout(ch);
p.setBody("question.question_excel");
p.setVar("p_title", "문항 일괄 등록");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("categories", categories);
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>