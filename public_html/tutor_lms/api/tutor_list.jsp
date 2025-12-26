<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 과목 복사 모달에서 담당 교수/강사를 전체 목록으로 선택할 수 있어야 합니다.
// - 향후 관리자 전용 메뉴로 제한될 예정이므로, 여기서도 관리자만 허용합니다.

if(!isAdmin) {
	result.put("rst_code", "4030");
	result.put("rst_message", "관리자 권한이 필요합니다.");
	result.print();
	return;
}

TutorDao tutor = new TutorDao();

DataSet list = tutor.query(
	" SELECT user_id, tutor_nm "
	+ " FROM " + tutor.table
	+ " WHERE site_id = " + siteId + " AND status = 1 "
	+ " ORDER BY sort ASC, tutor_nm ASC "
);

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_count", list.size());
result.put("rst_data", list);
result.print();

%>
