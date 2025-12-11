<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int lessonId = m.ri("lid");
if(lessonId == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//폼체크
f.addElement("lid", lessonId, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_complete_yn", null, null);

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
LessonDao lesson = new LessonDao();
TutorDao tutor = new TutorDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

//차시 정보
DataSet info = courseLesson.query(
	"SELECT a.* "
	+ ", le.lesson_nm, le.lesson_type "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " le ON a.lesson_id = le.id "
	+ " WHERE a.status != -1 AND a.course_id = " + courseId + " AND a.lesson_id = " + lessonId + " "
	//+ " AND le.onoff_type = 'F' AND le.lesson_type IN ('11', '12', '13', '14') "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("lesson_nm_conv", m.cutString(info.s("lesson_nm"), 30));
info.put("lesson_type_conv", m.getItem(info.s("lesson_type"), lesson.offlineTypes));

//출석 변경
if(m.isPost() && !"".equals(f.get("att_status"))) {

	//변수
	String today = m.time("yyyyMMdd");
	String now = m.time("yyyyMMddHHmmss");
	String[] uIdx = f.getArr("idx");
	String[] cuIdx = f.get("cu_idx").split(",");
	String attStatus = f.get("att_status");
	DataSet ulist = new DataSet();

	if(uIdx == null || uIdx.length != cuIdx.length) {
		m.jsError("올바른 정보가 아닙니다."); return;
	}

	for(int i=0, max=uIdx.length; i<max; i++) {
		ulist.addRow();
		ulist.put("course_user_id", cuIdx[i]);
		ulist.put("user_id", uIdx[i]);
		ulist.put("attend_status", attStatus);
	}

	m.jsAlert(uIdx.length + "건 중 " + courseProgress.attendUser(info, ulist, userId) + "건을 처리했습니다.");

	m.jsReplace("attend_user.jsp?" + m.qs(), "parent");
	return;
}

//차시
DataSet lessons = courseLesson.query(
	"SELECT a.*"
	+ ", l.lesson_nm "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " WHERE a.status != -1 AND a.course_id = " + courseId + " "
	//+ " AND l.onoff_type = 'F' AND l.lesson_type IN ('11', '12', '13', '14') "
	+ " ORDER BY a.chapter "
);

//목록
ListManager lm = new ListManager();
//lm.setDebug(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) ? 20000 : 100);
lm.setTable(
	courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id " + (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " LEFT JOIN " + courseProgress.table + " cp ON a.id = cp.course_user_id AND cp.lesson_id = " + lessonId + " AND cp.status = 1 "
);
lm.setFields(
	"a.* "
	+ ", u.user_nm, u.login_id "
	+ ", cp.ratio, cp.study_time, cp.complete_yn, cp.complete_date cp_complete_date "
);
lm.addWhere("a.status IN (1, 3) AND a.course_id = " + courseId);
if(!"".equals(f.get("s_complete_yn"))) {
	lm.addWhere(("Y".equals(f.get("s_complete_yn")) ? "" : "NOT " ) + "EXISTS (SELECT lesson_id FROM " + courseProgress.table + " WHERE course_user_id = a.id AND status = 1 AND lesson_id = " + lessonId + " AND complete_yn = 'Y')");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("u.user_nm,u.login_id", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	int time = list.i("study_time");
	list.put("study_time_conv", String.format("%02d:%02d:%02d", (time / 3600), (time % 3600 / 60), (time % 3600 % 60)));
	list.put("complete_date_conv", m.time("yyyy.MM.dd HH:mm", list.s("cp_complete_date")));
	list.put("progress_ratio_conv", m.nf(list.d("ratio"), 1));
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, info.s("lesson_nm") + "_출석현황(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "user_nm=>회원명", "login_id=>회원아이디", "progress_ratio_conv=>학습시간", "progress_ratio_conv=>진도율", "complete_date_conv=>완료일시", "complete_yn=>출석여부" }, info.s("lesson_nm") + "_출석현황(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}

//출력
p.setBody("management.attend_user");
p.setVar("p_title", ptitle);
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("lesson_query", m.qs("lid"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("lesson", info);
p.setLoop("lessons", lessons);

if("N".equals(cinfo.s("onoff_type"))) {
	p.setVar("attend", "완료");
	p.setVar("absent", "미완료");
} else {
	p.setVar("attend", "출석");
	p.setVar("absent", "결석");
}
p.display();

%>