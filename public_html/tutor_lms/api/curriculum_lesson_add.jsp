<%@ page pageEncoding="utf-8" %><%@ include file="init.jsp" %><%

//왜 필요한가:
//- 강의목차에서 레슨(영상/콘텐츠)을 특정 차시(섹션)에 추가할 수 있어야 합니다.
//- 기존 레슨을 선택(lesson_id)하거나, 외부 URL을 입력해서 새 레슨을 만들어 추가(url)할 수 있게 합니다.

if(!m.isPost()) {
	result.put("rst_code", "4050");
	result.put("rst_message", "POST 방식만 허용됩니다.");
	result.print();
	return;
}

int courseId = m.ri("course_id");
int sectionId = m.ri("section_id"); //0 허용
int lessonId = m.ri("lesson_id");   //없으면 url로 신규 생성
String url = m.rs("url").trim();
String title = m.rs("title").trim();

if(0 == courseId || (0 == lessonId && "".equals(url))) {
	result.put("rst_code", "1001");
	result.put("rst_message", "course_id와 (lesson_id 또는 url)가 필요합니다.");
	result.print();
	return;
}

CourseTutorDao courseTutor = new CourseTutorDao();
CourseLessonDao courseLesson = new CourseLessonDao();
LessonDao lesson = new LessonDao();

if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		result.put("rst_code", "4031");
		result.put("rst_message", "해당 과목의 강의목차를 수정할 권한이 없습니다.");
		result.print();
		return;
	}
}

//외부 URL이면 레슨 신규 생성
if(0 == lessonId) {
	lessonId = lesson.getSequence();
	lesson.item("id", lessonId);
	lesson.item("site_id", siteId);
	lesson.item("content_id", 0);
	lesson.item("onoff_type", "N");
	lesson.item("lesson_type", "04"); //외부링크
	lesson.item("lesson_nm", !"".equals(title) ? title : ("외부링크 " + lessonId));
	lesson.item("start_url", url);
	lesson.item("mobile_a", url);
	lesson.item("mobile_i", url);
	lesson.item("total_time", 0);
	lesson.item("complete_time", 0);
	lesson.item("total_page", 0);
	lesson.item("lesson_hour", 0);
	lesson.item("description", "");
	lesson.item("manager_id", userId);
	lesson.item("use_yn", "Y");
	lesson.item("chat_yn", "N");
	lesson.item("ai_chat_yn", "N");
	lesson.item("sort", 0);
	lesson.item("reg_date", m.time("yyyyMMddHHmmss"));
	lesson.item("status", 1);
	if(!lesson.insert()) {
		result.put("rst_code", "2000");
		result.put("rst_message", "외부 레슨 생성 중 오류가 발생했습니다.");
		result.print();
		return;
	}
} else {
	//존재 확인
	if(0 == lesson.findCount("id = " + lessonId + " AND site_id = " + siteId + " AND status = 1")) {
		result.put("rst_code", "4040");
		result.put("rst_message", "해당 레슨이 없습니다.");
		result.print();
		return;
	}
}

//중복 방지(같은 레슨을 같은 과목에 2번 넣으면 PK 충돌 가능)
if(0 < courseLesson.findCount("course_id = " + courseId + " AND lesson_id = " + lessonId + " AND status = 1")) {
	result.put("rst_code", "1200");
	result.put("rst_message", "이미 추가된 레슨입니다.");
	result.print();
	return;
}

int chapter = 0;
try { chapter = courseLesson.getOneInt("SELECT MAX(chapter) FROM " + courseLesson.table + " WHERE course_id = " + courseId + " AND status = 1"); }
catch(Exception ignore) {}
chapter++;

courseLesson.item("course_id", courseId);
courseLesson.item("lesson_id", lessonId);
courseLesson.item("section_id", sectionId);
courseLesson.item("site_id", siteId);
courseLesson.item("chapter", chapter);
courseLesson.item("start_day", 0);
courseLesson.item("period", 0);
courseLesson.item("start_date", "");
courseLesson.item("end_date", "");
courseLesson.item("start_time", "");
courseLesson.item("end_time", "");
courseLesson.item("lesson_hour", 1.00);
courseLesson.item("progress_yn", "Y");
courseLesson.item("status", 1);
if(!courseLesson.insert()) {
	result.put("rst_code", "2000");
	result.put("rst_message", "레슨 추가 중 오류가 발생했습니다.");
	result.print();
	return;
}

result.put("rst_code", "0000");
result.put("rst_message", "성공");
result.put("rst_data", lessonId);
result.print();

%>

