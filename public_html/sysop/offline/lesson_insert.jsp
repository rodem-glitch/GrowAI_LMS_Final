<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int courseId = m.ri("course_id");

//객체
LessonDao lesson = new LessonDao();
CourseDao course = new CourseDao();
CourseLessonDao courseLesson = new CourseLessonDao();
UserDao user = new UserDao();

//폼체크
f.addElement("lesson_type", "11", "hname:'구분', required:'Y'");
f.addElement("lesson_nm", null, "hname:'교과목명', required:'Y'");
f.addElement("lesson_hour", "1", "hname:'기본수업시수', required:'Y'");
f.addElement("lesson_file", null, "hname:'교안파일'");
f.addElement("description", null, "hname:'강의설명'");
if(!courseManagerBlock) f.addElement("manager_id", -99, "hname:'담당자'");
f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	int newId = lesson.getSequence();

	lesson.item("id", newId);
	lesson.item("site_id", siteId);
	lesson.item("lesson_nm", f.get("lesson_nm"));
	lesson.item("onoff_type", "F"); //오프라인
	lesson.item("lesson_type", f.get("lesson_type"));
	lesson.item("lesson_hour", f.getDouble("lesson_hour"));
	lesson.item("description", f.get("description"));
	lesson.item("manager_id", !courseManagerBlock ? f.getInt("manager_id") : userId);
	lesson.item("reg_date", m.time("yyyyMMddHHmmss"));
	lesson.item("status", f.getInt("status"));

	if(null != f.getFileName("lesson_file")) {
		File file1 = f.saveFile("lesson_file");
		if(null != file1) lesson.item("lesson_file", f.getFileName("lesson_file"));
	}
	if(!lesson.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

	//과정개설메뉴에서 신규강의 등록시
	if(courseId > 0) {

		DataSet cinfo2 = course.find("id = " + courseId);
		if(cinfo2.next()) {

			int maxChapter = courseLesson.getOneInt(
				"SELECT MAX(chapter) FROM " + courseLesson.table + " "
				+ " WHERE course_id = " + courseId + " "
			);

			courseLesson.item("course_id", courseId);
			courseLesson.item("site_id", siteId);
			courseLesson.item("start_day", 0);
			courseLesson.item("period", 0);
			courseLesson.item("start_date", cinfo2.s("study_sdate"));
			courseLesson.item("end_date", cinfo2.s("study_sdate"));
			courseLesson.item("start_time", "000000");
			courseLesson.item("end_time", "000000");
			courseLesson.item("tutor_id", 0);
			courseLesson.item("progress_yn", "Y");
			courseLesson.item("status", 1);
			courseLesson.item("lesson_id", newId);
			courseLesson.item("chapter", ++maxChapter);
			courseLesson.item("lesson_hour", f.getDouble("lesson_hour"));
			if(courseLesson.insert()) { 
				courseLesson.autoSort(courseId);
			}
		}

		m.js("try { parent.opener.location.href = parent.opener.location.href; } catch(e) { } parent.window.close();");
	} else {
		m.jsReplace("lesson_list.jsp?" + m.qs(), "parent");
	}

	return;

}

//출력
p.setLayout(courseId < 1 ? "sysop" : "pop");
p.setBody("offline.lesson_insert");
p.setVar("p_title", "집합강의관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("lesson_types", m.arr2loop(lesson.offlineTypes));
p.setLoop("status_list", m.arr2loop(lesson.statusList));
p.setLoop("managers", user.getManagers(siteId));
p.display();

%>