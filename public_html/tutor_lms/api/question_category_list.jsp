<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 시험관리 > 문제카테고리 화면에서 카테고리 트리를 DB에서 조회하기 위함입니다.
// - 기존 sysop/question 메뉴와 동일한 LM_QUESTION_CATEGORY 테이블을 사용합니다.

QuestionCategoryDao category = new QuestionCategoryDao();

// 해당 교수자의 카테고리만 조회
// 왜: 교수자는 본인이 만든 카테고리만 보이게 해야 합니다.
String whereClause = "status = 1 AND site_id = " + siteId;
if(!isAdmin) {
	whereClause += " AND manager_id = " + userId;
}

DataSet list = category.find(whereClause, "*", "depth ASC, sort ASC");

// 트리 구조로 변환하여 name_conv (경로명) 추가
list = category.getTreeSet(list);

// 응답 포맷팅
while(list.next()) {
	list.put("label", list.s("name_conv")); // 프론트엔드에서 사용할 라벨
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>
