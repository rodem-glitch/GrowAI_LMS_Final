<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
LessonDao lesson = new LessonDao();
TutorDao tutor = new TutorDao();
UserDao user = new UserDao();

//폼체크
f.addElement("lesson_idx", null, "hname:'강의'");
f.addElement("file", null, "hname:'파일', required:'Y', allow:'xls'");

//등록
if(m.isPost() && f.validate()) {
	
	//제한
	String lidx = m.join(",", f.getArr("lesson_idx"));
	if("".equals(lidx)) { m.jsError("선택한 강의가 없습니다."); return; }

	//정보-차시
	DataSet llist = courseLesson.query(
		" SELECT a.*, l.lesson_type "
		 + " FROM " + courseLesson.table + " a "
		 + " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
		 + " WHERE a.status != -1 AND a.course_id = " + courseId + " AND a.lesson_id IN (" + lidx + ") "
		+ " AND l.onoff_type = 'F' AND l.lesson_type IN ('11', '12', '13', '14') "
	);
	if(!llist.next()) { m.jsError("해당 정보가 없습니다."); return; }

	File file = f.saveFile("file");
	if(null != file) {
		String path = m.getUploadPath(f.getFileName("file"));
		DataSet ulist = new ExcelReader(path).getDataSet(1);
		m.delFile(path);

		//포맷팅
		while(ulist.next()) {
			ulist.put("course_user_id", ulist.i("col0"));
			ulist.put("user_id", ulist.i("col1"));
			ulist.put("attend_status", ulist.s("col4").toUpperCase());
		}

		//처리
		m.jsAlert((ulist.size() * llist.size()) + "건 중 " + courseProgress.attendUser(llist, ulist, userId) + "건을 처리했습니다.");
	}

	//이동
	m.jsReplace("course_lesson.jsp?cid=" + courseId, "parent");
	return;
}

//엑셀-샘플다운로드
if("sample".equals(m.rs("mode"))) {
	DataSet slist = courseUser.query(
		" SELECT a.*, u.user_nm, u.login_id, 'Y' attend_status "
		+ " FROM " + courseUser.table + " a "
		+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
		+ " WHERE a.status IN(1, 3) AND a.course_id = " + courseId
		+ " ORDER BY a.id DESC"
	);

	ExcelWriter ex = new ExcelWriter(response, cinfo.s("course_nm") + "_출석현황(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(slist, new String[] { "id=>고유값(수정불가)", "user_id=>회원PK(수정불가)", "user_nm=>회원명", "login_id=>회원아이디", "attend_status=>출석여부" });
	ex.write();
	return;

}

//목록-차시
DataSet lessons = courseLesson.query(
	"SELECT a.*"
	+ ", l.lesson_nm "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " WHERE a.status != -1 AND a.course_id = " + courseId + " "
	+ " AND l.onoff_type = 'F' AND l.lesson_type IN ('11', '12', '13' , '14') "
	+ " ORDER BY a.chapter "
);
while(lessons.next()) {
	lessons.put("start_date_conv", m.time("yyyy-MM-dd", lessons.s("start_date")));
	lessons.put("end_date_conv", m.time("yyyy-MM-dd", lessons.s("end_date")));

	lessons.put("start_time_hour", lessons.s("start_time").substring(0,2));
	lessons.put("start_time_min", lessons.s("start_time").substring(2,4));
	lessons.put("end_time_hour", lessons.s("end_time").substring(0,2));
	lessons.put("end_time_min", lessons.s("end_time").substring(2,4));
}


//출력
p.setBody("management.attend_excel");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("lesson_query", m.qs("lid, mode"));
p.setVar("form_script", f.getScript());

p.setLoop("lessons", lessons);
p.display();

%>