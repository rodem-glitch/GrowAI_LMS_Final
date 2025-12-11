<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%


//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

System.out.println("userKind====>"+userKind);


//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseProgressDao courseProgress = new CourseProgressDao();
ContentDao content = new ContentDao();
LessonDao lesson = new LessonDao();
//ContentLessonDao_ contentLesson_ = new ContentLessonDao_();

CourseTutorDao courseTutor = new CourseTutorDao();
TutorDao tutor = new TutorDao();


//정보
DataSet cinfo = course.find(
	"id = " + cid + " AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
cinfo.put("onoff_type_conv", m.getItem(cinfo.s("onoff_type"), course.onoffTypes));
cinfo.put("offline_block", "F".equals(cinfo.s("onoff_type")));

DataSet types = m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.types2 : lesson.catenoidTypes2);
if("N".equals(cinfo.s("onoff_type")))  {
	types = m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes);
	//if(cinfo.b("period_yn")) { types = m.arr2loop("W".equals(siteinfo.s("ovp_vendor")) ? lesson.lessonTypes : lesson.catenoidLessonTypes); }
} else if("F".equals(cinfo.s("onoff_type"))) {
	types = m.arr2loop(lesson.offlineTypes);
}

//정보-강사
DataSet tinfo = courseTutor.query(
	"SELECT a.*, t.tutor_nm "
	+ " FROM " + courseTutor.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON t.user_id = a.user_id "
	+ " WHERE a.course_id = " + cid + ""
	, 1
);
if(!tinfo.next()) {
	tinfo.addRow();
	tinfo.put("user_id", 0);
}

//등록
if(m.isPost() && f.validate()) {

	String[] idx = f.getArr("lidx");
	if(idx != null) {
		int maxChapter = courseLesson.getOneInt(
			"SELECT MAX(chapter) FROM " + courseLesson.table + " "
			+ " WHERE course_id = " + cid + " "
		);

		courseLesson.item("course_id", cid);
		courseLesson.item("site_id", siteId);
		courseLesson.item("start_day", 0);
		courseLesson.item("period", 0);

		courseLesson.item("start_date", cinfo.s("study_sdate"));
		courseLesson.item("end_date", cinfo.s("study_edate"));
		courseLesson.item("start_time", "000000");
		courseLesson.item("end_time", "235559");

		//courseLesson.item("tutor_id", tinfo.i("user_id"));
		courseLesson.item("progress_yn", "Y");
		courseLesson.item("status", 1);

		DataSet items = lesson.query(
			"SELECT a.* "
			+ " FROM " + lesson.table + " a "
			+ " WHERE a.status = 1 AND a.site_id = " + siteId + " "
			+ " AND a.id IN (" + m.join(",", idx) + ") "
			+ " AND NOT EXISTS ( "
				+ " SELECT 1 FROM " + courseLesson.table + " WHERE course_id = " + cid + " AND lesson_id = a.id "
			+ " ) "
			+ " ORDER BY a.content_id desc, a.sort asc, a.id desc "
		);
		while(items.next()) {
			courseLesson.item("lesson_id", items.s("id"));
			courseLesson.item("chapter", ++maxChapter);
			courseLesson.item("lesson_hour", items.d("lesson_hour"));

			if("15".equals(items.s("lesson_type"))) {
				courseLesson.item("start_date", "");
				courseLesson.item("end_date", "");
				courseLesson.item("start_time", "");
				courseLesson.item("end_time", "");
			}

			if(!courseLesson.insert()) { }

			if("Y".equals(SiteConfig.s("lesson_chat_yn")) && "Y".equals(items.s("chat_yn"))) {
				String channelId = lesson.getChannelId(siteinfo.s("ftp_id"), siteId, cid, items.i("id"), "c");
				String categoryNm = siteinfo.s("site_nm");
				lesson.insertChannel(channelId, categoryNm, "채팅방");
			}
		}
	}

	//갱신
	courseLesson.autoSort(cid);

	//삭제했던강의의진도복구
	DataSet culist = courseUser.find("course_id = " + cid + " AND status = 1", "id");
	StringBuffer sb = new StringBuffer();
	while(culist.next()) { sb.append(","); sb.append(culist.s("id")); }
	String cuidx = culist.size() == 0 ? "" : " AND course_user_id IN (" + sb.toString().substring(1) + ")";

	if(!"".equals(cuidx)) {
		courseProgress.item("status", 1);
		if(!courseProgress.update("course_id = " + cid + " AND lesson_id IN (" + m.join(",", idx) + ") AND status = -1" + cuidx)) {
			m.jsError("추가하는 중 오류가 발생했습니다.");
			return;
		}
	}

	m.jsAlert("성공적으로 추가했습니다.");
	m.js("opener.location.href = opener.location.href; window.close();");
	return;
}

//폼체크
f.addElement("s_content", null, null);
f.addElement("s_type", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(f.getInt("s_listnum", 20));
lm.setTable(lesson.table + " a LEFT JOIN " + content.table + " c ON c.id = a.content_id AND c.status = 1");
lm.setFields("a.*, c.content_nm");
lm.addWhere("a.status = 1");
lm.addWhere("a.use_yn = 'Y'");
lm.addWhere("a.site_id = " + siteId + "");

String type = cinfo.s("onoff_type");
if("B".equals(type)) { //혼합
	lm.addWhere("a.onoff_type != 'T'");
} else { //온라인/오프라인 과정
	lm.addWhere("a.onoff_type = '" + type + "'");
}

if("C".equals(userKind)) lm.addWhere("(a.onoff_type = 'F' OR c.manager_id = " + userId + ")");
//lm.addWhere("a.lesson_type != '" + ("W".equals(siteinfo.s("ovp_vendor")) ? "05" : "01") + "'");
lm.addWhere("NOT EXISTS ( SELECT 1 FROM " + courseLesson.table + " WHERE course_id = " + cid + " AND lesson_id = a.id )");
/* if(!"".equals(f.get("s_content"))) {
	lm.addWhere("EXISTS ( "
		+ " SELECT 1 FROM " + contentLesson_.table + " "
		+ " WHERE content_id = " + f.get("s_content") + " AND lesson_id = a.id"
	+ ")");
} */
lm.addSearch("a.content_id", f.get("s_content"));
lm.addSearch("a.lesson_type", f.get("s_type"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.lesson_nm, a.author, a.start_url, c.content_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.content_id desc, a.sort asc, a.id desc");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allTypes));
	list.put("moblie_block", !"".equals(list.s("mobile_a")) || !"".equals(list.s("mobile_i")));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), lesson.onoffTypes));
	list.put("total_time_conv", m.nf(list.i("total_time")));
	list.put("online_block", "N".equals(list.s("onoff_type")));
	list.put("content_nm_conv", 0 < list.i("content_id") ? list.s("content_nm") : "[미지정]");
}

//출력
p.setLayout("pop");
p.setBody("course.lesson_select");
p.setVar("p_title", cinfo.s("onoff_type_conv") + "과정 강의추가");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("course", cinfo);
p.setLoop("content_list", content.find(("C".equals(userKind) ? "manager_id = " + userId + " AND " : "") + "status != -1 AND site_id = " + siteId + "", "*", "content_nm ASC"));
p.setLoop("types", types);
p.display();

%>