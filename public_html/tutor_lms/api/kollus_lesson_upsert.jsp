<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 콜러스 목록의 media_content_key는 문자열이라서, 강의목차에는 레슨 ID(숫자)로 변환/등록이 필요합니다.
//- 이미 등록된 레슨이 있으면 그대로 쓰고, 없으면 새로 생성합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

String mediaKey = m.rs("media_content_key").trim();
String title = m.rs("title").trim();
int totalTime = m.ri("total_time");
int contentWidth = m.ri("content_width");
int contentHeight = m.ri("content_height");

if("".equals(mediaKey)) {
	result.put("rst_code", "1001");
	result.put("rst_message", "media_content_key가 필요합니다.");
	result.print();
	return;
}

LessonDao lesson = new LessonDao();
DataSet info = lesson.find("site_id = " + siteId + " AND start_url = '" + mediaKey + "' AND lesson_type = '05' AND status != -1");
if(info.next()) {
	result.put("rst_code", "0000");
	result.put("rst_message", "성공");
	result.put("rst_data", info.i("id"));
	result.print();
	return;
}

int lessonId = lesson.getSequence();
lesson.item("id", lessonId);
lesson.item("site_id", siteId);
lesson.item("content_id", 0);
lesson.item("lesson_nm", !"".equals(title) ? title : ("콜러스 " + mediaKey));
lesson.item("onoff_type", "N");
lesson.item("lesson_type", "05");
lesson.item("author", "");
lesson.item("start_url", mediaKey);
lesson.item("mobile_a", mediaKey);
lesson.item("mobile_i", mediaKey);
lesson.item("total_page", 0);
lesson.item("total_time", totalTime);
lesson.item("complete_time", totalTime);
lesson.item("content_width", contentWidth);
lesson.item("content_height", contentHeight);
lesson.item("description", "");
lesson.item("manager_id", userId);
lesson.item("use_yn", "Y");
lesson.item("sort", 0);
lesson.item("reg_date", m.time("yyyyMMddHHmmss"));
lesson.item("status", 1);

if(!lesson.insert()) {
	result.put("rst_code", "2000");
	result.put("rst_message", "콜러스 레슨 생성 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", lessonId);
result.print();

%>
