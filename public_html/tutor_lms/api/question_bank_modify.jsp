<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 문제은행에서 기존 문제를 수정하기 위함입니다.

QuestionDao question = new QuestionDao();

// 파라미터 수집
int questionId = m.ri("id");
int categoryId = m.ri("category_id");
int questionType = m.ri("question_type");
String questionTitle = m.rs("question");
String questionText = m.rs("question_text");
int grade = m.ri("grade");
String answer = m.rs("answer");
String description = m.rs("description");

// 검증
if(questionId <= 0) {
	result.put("rst_code", "1001");
	result.put("rst_message", "문제 ID가 필요합니다.");
	result.print();
	return;
}

// 기존 문제 확인
DataSet info = question.find("id = " + questionId + " AND site_id = " + siteId + " AND status = 1");
if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 문제가 존재하지 않습니다.");
	result.print();
	return;
}

// 권한 확인
if(!isAdmin && info.i("manager_id") != userId && info.i("manager_id") != -99) {
	result.put("rst_code", "4030");
	result.put("rst_message", "해당 문제를 수정할 권한이 없습니다.");
	result.print();
	return;
}

// 수정
if(categoryId > 0) question.item("category_id", categoryId);
if(questionType > 0) question.item("question_type", questionType);
if(!"".equals(questionTitle)) question.item("question", questionTitle);
question.item("question_text", questionText);
if(grade > 0) question.item("grade", grade);
question.item("answer", answer);
question.item("description", description);
// 객관식 보기 처리
int checkType = questionType > 0 ? questionType : info.i("question_type");
boolean isChoice = (checkType == 1 || checkType == 2);
if(isChoice) {
	int itemCnt = 0;
	for(int i = 1; i <= 5; i++) {
		String itemText = m.rs("item" + i);
		question.item("item" + i, itemText);
		if(!"".equals(itemText)) itemCnt = i;
	}
	// 왜: 보기 수가 비어도 최소 4개를 유지해서 화면/DB 불일치를 막습니다.
	question.item("item_cnt", itemCnt > 0 ? itemCnt : 4);
} else {
	// 왜: 주관식으로 바뀌면 기존 보기 정보를 비워서 문제 유형과 맞춥니다.
	question.item("item_cnt", 1);
	for(int i = 1; i <= 5; i++) {
		question.item("item" + i, "");
		question.item("item" + i + "_file", "");
	}
}

if(!question.update("id = " + questionId + " AND site_id = " + siteId)) {
	result.put("rst_code", "5000");
	result.put("rst_message", "문제 수정 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "문제가 수정되었습니다.");
result.put("rst_data", questionId);
result.print();

%>
