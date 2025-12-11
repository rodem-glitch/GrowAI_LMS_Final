<%@ page contentType="application/json; charset=utf-8" %><%@ include file="../init.jsp" %><%

//객체
Json result = new Json(out);
result.put("rst_code", "9999");
result.put("rst_message", "올바른 접근이 아닙니다.");

Json resultData = new Json(out);

//기본키
int courseUserId = m.ri("cuid");
int lessonId = m.ri("lid");
if(1 > courseUserId || 1 > lessonId) { result.put("rst_message", "기본키는 반드시 지정해야 합니다."); result.print(); return; }

//폼입력
int uid = m.ri("uid");
int studyTime = m.ri("study_time");

//객체
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseProgressDao courseProgress = new CourseProgressDao();

LessonDao lesson = new LessonDao();

//폼체크
f.addElement("studyTime", null, "hname:'섹션명', option:'number', min:'0'");

//등록
//if(f.validate()) {
if(m.isPost() && f.validate()) {

	DataSet linfo = courseLesson.query(
		"SELECT a.*"
		+ ", l.lesson_nm, l.lesson_type, l.total_time, l.complete_time "
		+ ", p.course_user_id, p.complete_yn, p.ratio, p.complete_date, p.last_date "
		+ " FROM " + courseLesson.table + " a "
		+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
		+ " INNER JOIN " + courseProgress.table + " p ON "
			+ " p.course_id = a.course_id AND p.lesson_id = a.lesson_id AND p.course_user_id = " + courseUserId + " "
		+ " WHERE a.status = 1 AND a.lesson_id = " + lessonId
	);
	if(!linfo.next()) { result.put("rst_message", "해당 정보가 없습니다."); result.print(); return; }

	//변수-진도율처리
	/*
	String completeYn = "N";
	double ratio = 100.0;
	if(linfo.i("total_time") * 60 > 0 && studyTime < linfo.i("complete_time") * 60) {
		ratio = Math.min(100.0, (studyTime / (linfo.d("total_time") * 60)) * 100);
	}
	if(ratio >= 100.0) completeYn = "Y";
	String completeDate = "Y".equals(completeYn) ? sysNow : "";
	*/

	//처리
	courseProgress.item("study_time", studyTime);
	courseProgress.item("curr_time", studyTime);
	courseProgress.item("last_time", studyTime);
	//courseProgress.item("ratio", ratio);
	//courseProgress.item("complete_yn", completeYn);
	//courseProgress.item("last_date", now);
	//courseProgress.item("complete_date", completeDate);
	courseProgress.item("change_user_id", userId);
	if(!courseProgress.update("course_id = " + linfo.i("course_id") + " AND lesson_id = " + lessonId + " AND course_user_id = " + courseUserId + "" )) {
		result.put("rst_message", "수정하는 중 오류가 발생했습니다."); result.print(); return;
	}

	//courseUser.setProgressRatio(courseUserId);
	//courseUser.updateScore(courseUserId, "progress"); //점수일괄업데이트

	//출력
	resultData.put("study_time_conv", m.nf(studyTime));
	//resultData.put("ratio_conv", m.nf(ratio, 1));
	//resultData.put("complete_conv", "Y".equals(completeYn) ? "완료" : "-");
	//resultData.put("complete_date_conv", !"".equals(completeDate) ? m.time("yyyy.MM.dd HH:mm", completeDate) : "-");

	result.put("rst_code", "0000");
	result.put("rst_message", "성공");
	result.put("rst_data", resultData);
}

result.print();

%>