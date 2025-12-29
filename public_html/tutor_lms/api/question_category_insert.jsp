<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 문제카테고리에서 새 카테고리를 추가하기 위함입니다.

QuestionCategoryDao category = new QuestionCategoryDao();

// 파라미터 검증
String categoryName = m.rs("category_nm");
int parentId = m.ri("parent_id");

if("".equals(categoryName)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "카테고리명이 필요합니다.");
	result.print();
	return;
}

// 부모 카테고리 존재 여부 확인 (0이 아닌 경우)
int depth = 1;
int sort = 1;
if(parentId > 0) {
	DataSet parentInfo = category.find("id = " + parentId + " AND site_id = " + siteId + " AND status = 1");
	if(!parentInfo.next()) {
		result.put("rst_code", "4040");
		result.put("rst_message", "상위 카테고리가 존재하지 않습니다.");
		result.print();
		return;
	}
	depth = parentInfo.i("depth") + 1;
}

// 같은 레벨의 마지막 sort 값 조회
DataSet lastSort = category.query(
	"SELECT MAX(sort) max_sort FROM " + category.table 
	+ " WHERE site_id = " + siteId + " AND parent_id = " + parentId + " AND status = 1"
);
if(lastSort.next()) {
	sort = lastSort.i("max_sort") + 1;
}

// 새 카테고리 등록
int newId = category.getSequence();
category.item("id", newId);
category.item("site_id", siteId);
category.item("parent_id", parentId);
category.item("category_nm", categoryName);
category.item("depth", depth);
category.item("sort", sort);
category.item("manager_id", userId); // 교수자 본인 소유
category.item("status", 1);

if(!category.insert()) {
	result.put("rst_code", "5000");
	result.put("rst_message", "카테고리 등록 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "카테고리가 등록되었습니다.");
result.put("rst_data", newId);
result.print();

%>
