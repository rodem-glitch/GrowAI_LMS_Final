<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

// 왜 필요한가:
// - 교수자 LMS > 시험관리에서 시험 템플릿을 삭제하기 위함입니다.

ExamDao exam = new ExamDao();

// 파라미터
int examId = m.ri("id");

if(examId <= 0) {
	result.put("rst_code", "1001");
	result.put("rst_message", "시험 ID가 필요합니다.");
	result.print();
	return;
}

// 기존 시험 확인
DataSet info = exam.find("id = " + examId + " AND site_id = " + siteId + " AND status != -1");
if(!info.next()) {
	result.put("rst_code", "4040");
	result.put("rst_message", "해당 시험이 존재하지 않습니다.");
	result.print();
	return;
}

// 권한 확인
if(!isAdmin && info.i("manager_id") != userId && info.i("manager_id") != -99) {
	result.put("rst_code", "4030");
	result.put("rst_message", "해당 시험을 삭제할 권한이 없습니다.");
	result.print();
	return;
}

// 소프트 삭제 (status = -1)
exam.item("status", -1);

if(!exam.update("id = " + examId + " AND site_id = " + siteId)) {
	result.put("rst_code", "5000");
	result.put("rst_message", "시험 삭제 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "시험이 삭제되었습니다.");
result.put("rst_data", examId);
result.print();

%>
