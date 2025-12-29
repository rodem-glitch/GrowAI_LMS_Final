<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 문제카테고리에서 기존 카테고리를 수정하기 위함입니다.

QuestionCategoryDao category = new QuestionCategoryDao();

// 파라미터 검증
int categoryId = m.ri("id");
String categoryName = m.rs("category_nm");
int parentId = m.ri("parent_id");

if(categoryId <= 0) {
	result.put("rst_code", "1001");
	result.put("rst_message", "카테고리 ID가 필요합니다.");
	result.print();
	return;
}

if("".equals(categoryName)) {
	result.put("rst_code", "1002");
	result.put("rst_message", "카테고리명이 필요합니다.");
	result.print();
	return;
}

// 기존 카테고리 확인 + 권한 체크
DataSet info = category.find("id = " + categoryId + " AND site_id = " + siteId + " AND status = 1");
if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 카테고리가 존재하지 않습니다.");
	result.print();
	return;
}

// 권한 확인: 본인 카테고리거나 관리자만 수정 가능
if(!isAdmin && info.i("manager_id") != userId && info.i("manager_id") != -99) {
	result.put("rst_code", "4030");
	result.put("rst_message", "해당 카테고리를 수정할 권한이 없습니다.");
	result.print();
	return;
}

// 자기 자신을 부모로 설정하는 것 방지
if(parentId == categoryId) {
	result.put("rst_code", "4001");
	result.put("rst_message", "자기 자신을 상위 카테고리로 설정할 수 없습니다.");
	result.print();
	return;
}

// 부모 변경 시 depth 재계산
int depth = 1;
if(parentId > 0) {
	DataSet parentInfo = category.find("id = " + parentId + " AND site_id = " + siteId + " AND status = 1");
	if(!parentInfo.next()) {
		result.put("rst_code", "4041");
		result.put("rst_message", "상위 카테고리가 존재하지 않습니다.");
		result.print();
		return;
	}
	depth = parentInfo.i("depth") + 1;
}

// 수정
category.item("category_nm", categoryName);
category.item("parent_id", parentId);
category.item("depth", depth);

if(!category.update("id = " + categoryId + " AND site_id = " + siteId)) {
	result.put("rst_code", "5000");
	result.put("rst_message", "카테고리 수정 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "카테고리가 수정되었습니다.");
result.put("rst_data", categoryId);
result.print();

%>
