<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- PLISM(교수자 UI)에서 "과정 카테고리"를 텍스트로 대충 적으면, 관리자(sysop)의 카테고리(LM_CATEGORY)와 서로 달라져서
//  "과목을 만들었는데 어디에도 안 보이는 것처럼" 느껴질 수 있습니다.
//- 그래서 관리자와 동일한 카테고리 목록(LM_CATEGORY)을 API로 내려주고, 화면에서는 그 목록 중에서만 선택하게 합니다.

LmCategoryDao category = new LmCategoryDao("course");

DataSet list = new DataSet();
try {
	list = category.getList(siteId);
	while(list.next()) {
		//왜: 프론트 드롭다운에서 "트리(상위 > 하위)" 형태로 바로 보여주기 위해 label을 만들어 둡니다.
		String label = !"".equals(list.s("name_conv")) ? list.s("name_conv") : list.s("category_nm");
		list.put("label", label);
	}
	list.first();
} catch(Exception e) {
	result.put("rst_code", "5000");
	result.put("rst_message", "카테고리 목록을 불러오는 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>

