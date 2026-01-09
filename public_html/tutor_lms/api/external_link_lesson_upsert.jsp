<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 교수 차시관리에서 콜러스 영상 외에 "외부링크(URL)"를 직접 입력하여 레슨으로 등록하기 위함입니다.
//- 이미 동일한 URL의 레슨이 있으면 그대로 사용하고, 없으면 새로 생성합니다.
//- lesson_type = '04' (외부링크)

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

String url = m.rs("url").trim();
String title = m.rs("title").trim();
int totalTime = m.ri("total_time"); // 분 단위

// 필수값 검증
if("".equals(url)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "외부링크 URL이 필요합니다.");
	result.print();
	return;
}

if("".equals(title)) {
	result.put("rst_code", "1002");
	result.put("rst_message", "강의명이 필요합니다.");
	result.print();
	return;
}

// URL 형식 간단 검증 (http 또는 https로 시작해야 함)
if(!url.startsWith("http://") && !url.startsWith("https://")) {
	result.put("rst_code", "1003");
	result.put("rst_message", "URL은 http:// 또는 https://로 시작해야 합니다.");
	result.print();
	return;
}

LessonDao lesson = new LessonDao();

// 동일한 URL의 외부링크 레슨이 이미 존재하는지 확인
DataSet info = lesson.find("site_id = " + siteId + " AND start_url = '" + m.addSlashes(url) + "' AND lesson_type = '04' AND status != -1");
if(info.next()) {
	// 이미 존재하면 기존 ID 반환
	result.put("rst_code", "0000");
	result.put("rst_message", "성공");
	result.put("rst_data", info.i("id"));
	result.print();
	return;
}

// 새 레슨 생성
int lessonId = lesson.getSequence();
lesson.item("id", lessonId);
lesson.item("site_id", siteId);
lesson.item("content_id", 0);
lesson.item("lesson_nm", title);
lesson.item("onoff_type", "N"); // 온라인
lesson.item("lesson_type", "04"); // 외부링크
lesson.item("author", "");
lesson.item("start_url", url);
lesson.item("mobile_a", url); // 모바일도 동일 URL
lesson.item("mobile_i", url);
lesson.item("total_page", 0);
lesson.item("total_time", totalTime);
lesson.item("complete_time", totalTime);
lesson.item("content_width", 0);
lesson.item("content_height", 0);
lesson.item("description", "");
lesson.item("manager_id", userId);
lesson.item("use_yn", "Y");
lesson.item("sort", 0);
lesson.item("reg_date", m.time("yyyyMMddHHmmss"));
lesson.item("status", 1);

if(!lesson.insert()) {
	result.put("rst_code", "2000");
	result.put("rst_message", "외부링크 레슨 생성 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", lessonId);
result.print();

%>
