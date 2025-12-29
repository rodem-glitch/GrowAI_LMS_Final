<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 문제카테고리에서 카테고리를 삭제하기 위함입니다.
// - 하위 카테고리가 있으면 삭제 불가합니다.

QuestionCategoryDao category = new QuestionCategoryDao();
QuestionDao question = new QuestionDao();

// 파라미터 검증
int categoryId = m.ri("id");

if(categoryId <= 0) {
	result.put("rst_code", "1001");
	result.put("rst_message", "카테고리 ID가 필요합니다.");
	result.print();
	return;
}

// 기존 카테고리 확인
DataSet info = category.find("id = " + categoryId + " AND site_id = " + siteId + " AND status = 1");
if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 카테고리가 존재하지 않습니다.");
	result.print();
	return;
}

// 권한 확인: 본인 카테고리거나 관리자만 삭제 가능
if(!isAdmin && info.i("manager_id") != userId && info.i("manager_id") != -99) {
	result.put("rst_code", "4030");
	result.put("rst_message", "해당 카테고리를 삭제할 권한이 없습니다.");
	result.print();
	return;
}

// 하위 카테고리 존재 여부 확인
int childCount = category.findCount("parent_id = " + categoryId + " AND site_id = " + siteId + " AND status = 1");
if(childCount > 0) {
	result.put("rst_code", "4002");
	result.put("rst_message", "하위 카테고리가 있어 삭제할 수 없습니다. 하위 카테고리를 먼저 삭제해주세요.");
	result.print();
	return;
}

// 해당 카테고리에 문제가 있는지 확인
int questionCount = question.findCount("category_id = " + categoryId + " AND site_id = " + siteId + " AND status != -1");
if(questionCount > 0) {
	result.put("rst_code", "4003");
	result.put("rst_message", "해당 카테고리에 " + questionCount + "개의 문제가 있어 삭제할 수 없습니다.");
	result.print();
	return;
}

// 소프트 삭제 (status = -1)
category.item("status", -1);

if(!category.update("id = " + categoryId + " AND site_id = " + siteId)) {
	result.put("rst_code", "5000");
	result.put("rst_message", "카테고리 삭제 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "카테고리가 삭제되었습니다.");
result.put("rst_data", categoryId);
result.print();

%>
