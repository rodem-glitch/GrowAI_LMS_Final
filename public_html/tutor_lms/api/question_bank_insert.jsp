<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 문제은행에서 새 문제를 등록하기 위함입니다.
// - 객관식(단일/다중선택), 주관식(단답형/서술형) 유형을 지원합니다.

QuestionDao question = new QuestionDao();

// 파라미터 수집
int categoryId = m.ri("category_id");
int questionType = m.ri("question_type"); // 1=단일선택, 2=다중선택, 3=단답형, 4=서술형
String questionTitle = m.rs("question");
String questionText = m.rs("question_text");
int grade = m.ri("grade") > 0 ? m.ri("grade") : 3; // 기본 난이도 C
String answer = m.rs("answer");
String description = m.rs("description");

// 검증
if(questionType < 1 || questionType > 4) {
	result.put("rst_code", "1001");
	result.put("rst_message", "문제 유형이 올바르지 않습니다. (1=단일선택, 2=다중선택, 3=단답형, 4=서술형)");
	result.print();
	return;
}

if("".equals(questionTitle)) {
	result.put("rst_code", "1002");
	result.put("rst_message", "문제 제목이 필요합니다.");
	result.print();
	return;
}

// 등록
int newId = question.getSequence();
question.item("id", newId);
question.item("site_id", siteId);
question.item("category_id", categoryId);
question.item("question_type", questionType);
question.item("question", questionTitle);
question.item("question_text", questionText);
question.item("grade", grade);
question.item("answer", answer);
question.item("description", description);
question.item("manager_id", userId);
question.item("reg_date", m.time("yyyyMMddHHmmss"));
question.item("status", 1);

// 객관식 보기 처리 (item1~item5)
boolean isChoice = (questionType == 1 || questionType == 2);
if(isChoice) {
	int itemCnt = 0;
	for(int i = 1; i <= 5; i++) {
		String itemText = m.rs("item" + i);
		if(!"".equals(itemText)) {
			question.item("item" + i, itemText);
			itemCnt = i;
		} else {
			question.item("item" + i, "");
		}
		question.item("item" + i + "_file", "");
	}
	// 왜: 객관식인데 보기가 비어있으면 기본 4개로 잡아 저장 오류를 피합니다.
	question.item("item_cnt", itemCnt > 0 ? itemCnt : 4);
} else {
	// 주관식인 경우 보기 컬럼 비움
	question.item("item_cnt", 1);
	for(int i = 1; i <= 5; i++) {
		question.item("item" + i, "");
		question.item("item" + i + "_file", "");
	}
}

if(!question.insert()) {
	result.put("rst_code", "5000");
	result.put("rst_message", "문제 등록 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "문제가 등록되었습니다.");
result.put("rst_data", newId);
result.print();

%>
