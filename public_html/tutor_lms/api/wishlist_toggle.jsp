<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 콘텐츠(레슨) 모달에서 "찜"을 눌렀을 때 즐겨찾기를 토글해야 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

String module = m.rs("module");
int moduleId = m.ri("module_id");
if("".equals(module) || 0 == moduleId) {
	result.put("rst_code", "1001");
	result.put("rst_message", "module과 module_id가 필요합니다.");
	result.print();
	return;
}

WishlistDao wishlist = new WishlistDao(siteId);
int state = wishlist.toggle(userId, module, moduleId); //1=추가,0=삭제,-1=오류
if(state < 0) {
	result.put("rst_code", "2000");
	result.put("rst_message", "찜 처리 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", state);
result.print();

%>

