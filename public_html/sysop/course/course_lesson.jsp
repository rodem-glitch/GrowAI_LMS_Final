<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseLessonDao courseLesson = new CourseLessonDao();
CourseSectionDao courseSection = new CourseSectionDao();
CourseProgressDao courseProgress = new CourseProgressDao();
CourseUserDao courseUser = new CourseUserDao();
LessonDao lesson = new LessonDao();
// 왜: 차시별 서브영상(다중영상) 정보를 한꺼번에 조회해 목록에 표시하기 위함입니다.
CourseLessonVideoDao courseLessonVideo = new CourseLessonVideoDao();
CourseTutorDao courseTutor = new CourseTutorDao();
TutorDao tutor = new TutorDao();
UserDao user = new UserDao();
MCal mcal = new MCal();

//카테고리
DataSet categories = category.getList(siteId);

//정보-과정
DataSet cinfo = course.find(
	"id = " + cid + " AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
cinfo.put("cate_name", category.getTreeNames(cinfo.i("category_id")));
cinfo.put("status_conv", m.getItem(cinfo.s("status"), course.statusList));
if("R".equals(cinfo.s("course_type"))) {
	cinfo.put("request_date", m.time("yyyy.MM.dd", cinfo.s("request_sdate")) + " - " + m.time("yyyy.MM.dd", cinfo.s("request_edate")));
	cinfo.put("study_date", m.time("yyyy.MM.dd", cinfo.s("study_sdate")) + " - " + m.time("yyyy.MM.dd", cinfo.s("study_edate")));
	cinfo.put("course_type_conv", "정규");
	cinfo.put("study_sdate_conv", m.time("yyyy-MM-dd", cinfo.s("study_sdate")));
	cinfo.put("study_edate_conv", m.time("yyyy-MM-dd", cinfo.s("study_edate")));
	cinfo.put("alltime_block", false);
} else if("A".equals(cinfo.s("course_type"))) {
	cinfo.put("request_date", "상시");
	cinfo.put("study_date", "상시");
	cinfo.put("course_type_conv", "상시");
	cinfo.put("alltime_block", true);
}
cinfo.put("period_conv", cinfo.b("period_yn") ? "학습기간 설정" : "-");
cinfo.put("lesson_order_conv", cinfo.b("lesson_order_yn") ? "순차학습" : "-");
cinfo.put("course_type_conv", m.getItem(cinfo.s("course_type"), course.types));
cinfo.put("onoff_type_conv", m.getItem(cinfo.s("onoff_type"), course.onoffTypes));
cinfo.put("online_block", "N".equals(cinfo.s("onoff_type")));
cinfo.put("display_conv", cinfo.b("display_yn") ? "정상" : "숨김");


DataSet rs = courseUser.find("course_id = " + cid + " AND status = 1", "id");
StringBuffer sb = new StringBuffer();
while(rs.next()) { sb.append(","); sb.append(rs.s("id")); }
String userIdx = rs.size() == 0 ? "" : " AND course_user_id IN (" + sb.toString().substring(1) + ")";

int progressCnt = !"".equals(userIdx) ? courseProgress.findCount("course_id = " + cid + " AND status != -1" + userIdx) : 0;
boolean isModify = 0 == progressCnt; //수정가능여부
cinfo.put("delete_block", isModify);
cinfo.put("progress_cnt_conv", m.nf(progressCnt));

//종료여부
boolean closed = cinfo.b("close_yn");

//삭제
if("del".equals(m.rs("mode"))) {
	if("".equals(f.get("idx")) && "".equals(f.get("sidx"))) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//제한
	if(closed) { m.jsAlert("해당 과정은 종료되어 강의를 삭제할 수 없습니다."); return; }

	//강의삭제
	if(!"".equals(f.get("idx"))) {

		DataSet clist = courseLesson.query(
			 "SELECT a.course_id, a.lesson_id, a.twoway_url, a.host_num, a.tutor_id, l.lesson_type"
			+ " FROM " + courseLesson.table + " a "
			+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.site_id = " + siteId
			+ " WHERE a.course_id = " + cid + " AND a.lesson_id IN (" + f.get("idx") + ")"
			+ " AND a.site_id = " + siteId
		);

		while(clist.next()) {

			if(!courseLesson.delete("course_id = " + clist.i("course_id") + " AND lesson_id = " + clist.i("lesson_id") + " AND site_id = " + siteId)) {
				m.jsError("강의를 삭제하는 중 오류가 발생했습니다.");
				return;
			}
		}

		//진도삭제
		if(!"".equals(userIdx)) {
			courseProgress.item("status", -1);
			if(!courseProgress.update("course_id = " + cid + " AND lesson_id IN (" + f.get("idx") + ") AND status != -1" + userIdx)) {
				m.jsError("삭제하는 중 오류가 발생했습니다.");
				return;
			}
		}
	}

	//섹션삭제
	courseSection.item("status", -1);
	if(!"".equals(f.get("sidx")) && !courseSection.update("id IN (" + f.get("sidx") + ")")) {
		m.jsError("섹션을 삭제하는 중 오류가 발생했습니다.");
		return;
	};

	courseLesson.autoSort(cid);

	//이동
	m.jsReplace("course_lesson.jsp?" + m.qs("mode, idx, sidx"));
	return;
}

//폼체크
f.addElement("lesson_display_ord", cinfo.s("lesson_display_ord"), "hname:'강의실 정렬기준', required:'Y'");

//수정
if(m.isPost() && f.validate()) {
	if(f.getArr("lesson_id") != null) {
		int sort = 0;
		int sectionId = 0;
		int lessonIdx = 0;

		for(int i = 0; i < f.getArr("lesson_id").length; i++) {
			if("section".equals(f.getArr("lesson_id")[i])) {
				sectionId = m.parseInt(f.getArr("section_id")[i]);
				//courseSection.item("section_nm", f.getArr("section_nm")[i]);
				//if(!courseSection.update("id = " + sectionId)) { }
			} else {

				if(cinfo.b("period_yn")) {
					if("".equals(f.getArr("start_time_hour")[i])
							&& (!"".equals(f.getArr("start_time_min")[i]) || !"".equals(f.getArr("end_time_hour")[i]) || !"".equals(f.getArr("end_time_min")[i]))
						|| !"".equals(f.getArr("start_time_hour")[i])
							&& ("".equals(f.getArr("start_time_min")[i]) || "".equals(f.getArr("end_time_hour")[i]) || "".equals(f.getArr("end_time_min")[i]))) {
						m.jsAlert("학습기간 시작/종료시간의 설정은 없음 또는 시분 값으로 일치하여야 합니다.");
						return;
					}
				}

				courseLesson.item("section_id", sectionId);
				courseLesson.item("chapter", ++sort);
				courseLesson.item("lesson_hour", m.parseDouble(f.getArr("lesson_hour")[i]));
				courseLesson.item("start_day", f.getArr("start_day")[i]);
				courseLesson.item("period", f.getArr("period")[i]);

				courseLesson.item("tutor_id", !"".equals(f.getArr("tutor_id")[i]) ? f.getArr("tutor_id")[i] : 0);
				courseLesson.item("start_date", m.time("yyyyMMdd", f.getArr("start_date")[i]));
				courseLesson.item("end_date", m.time("yyyyMMdd", f.getArr("end_date")[i]));
				courseLesson.item("start_time", "");
				if(!"".equals(f.getArr("start_time_hour")[i]) && !"".equals(f.getArr("start_time_min")[i])) courseLesson.item("start_time", f.getArr("start_time_hour")[i] + f.getArr("start_time_min")[i] + "00");
				courseLesson.item("end_time", "");
				if(!"".equals(f.getArr("end_time_hour")[i]) && !"".equals(f.getArr("end_time_min")[i])) courseLesson.item("end_time", f.getArr("end_time_hour")[i] + f.getArr("end_time_min")[i] + "59");

				if(!courseLesson.update("course_id = " + cid + " AND lesson_id = " + f.getArr("lesson_id")[i])) { }
			}
		}
	}

	//과정설정
	course.item("lesson_display_ord", f.get("lesson_display_ord", "A"));
	if(!course.update("id = " + cid + " AND site_id = " + siteId)) { }

	m.jsAlert("수정되었습니다.");
	m.jsReplace("course_lesson.jsp?" + m.qs(), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(1000);
lm.setTable(
	courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " b ON a.lesson_id = b.id "
	+ " LEFT JOIN " + courseSection.table + " cs ON a.section_id = cs.id AND a.course_id = cs.course_id AND cs.status = 1 "
);
lm.setFields(
	"a.*"
	+ ", b.content_id, b.onoff_type, b.lesson_nm, b.lesson_type, b.total_time, b.complete_time, b.content_width, b.content_height, b.start_url, b.mobile_a, b.mobile_i "
	+ ", cs.id section_id, cs.course_id section_course_id, cs.section_nm "
);
lm.addWhere("a.status != -1");
lm.addWhere("a.course_id = " + cid + "");
lm.setOrderBy("a.chapter ASC");

// 차시별 서브영상 리스트/개수 미리 조회
// 왜: 목록 렌더링 시 매 차시마다 DB를 다시 조회하지 않도록 미리 한 번에 가져옵니다.
java.util.HashMap<Integer, DataSet> videoByLesson = new java.util.HashMap<Integer, DataSet>();
DataSet videoRows = courseLessonVideo.query(
	"SELECT v.lesson_id, v.video_id, v.sort"
	+ ", l.lesson_nm, l.total_time, l.complete_time "
	+ " FROM " + courseLessonVideo.table + " v "
	+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 "
	+ " WHERE v.course_id = " + cid
	+ " AND v.site_id = " + siteId
	+ " AND v.status = 1 "
	+ " ORDER BY v.lesson_id ASC, v.sort ASC "
);
while(videoRows.next()) {
	int lId = videoRows.i("lesson_id");
	if(!videoByLesson.containsKey(lId)) videoByLesson.put(lId, new DataSet());
	DataSet rows = videoByLesson.get(lId);
	rows.addRow();
	rows.put("ord", rows.size()); // 화면용 순번
	rows.put("lesson_nm", videoRows.s("lesson_nm"));
	rows.put("total_time", videoRows.i("total_time"));
	rows.put("complete_time", videoRows.i("complete_time"));
	rows.put("video_id", videoRows.i("video_id"));
	rows.put("lesson_id", lId);
}

//포맷팅
int idx = 0;
int lastSectionId = 0;
DataSet sortList = new DataSet();
DataSet list = lm.getDataSet();
Integer[] sidx = new Integer[list.size()];
while(list.next()) {
	//다중영상 차시는 과정-차시 테이블 합산시간을 표시합니다.
	if("Y".equals(list.s("multi_yn"))) {
		if(list.i("multi_total_time") > 0) list.put("total_time", list.i("multi_total_time"));
		if(list.i("multi_complete_time") > 0) list.put("complete_time", list.i("multi_complete_time"));
		list.put("multi_block", true);
	} else {
		list.put("multi_block", false);
	}
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 55));
	//list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), "W".equals(siteinfo.s("ovp_vendor")) ? lesson.types : lesson.catenoidTypes));
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allTypes));
	list.put("pc_block", !"".equals(list.s("start_url")));
	list.put("ios_block", !"".equals(list.s("mobile_i")));
	list.put("android_block", !"".equals(list.s("mobile_a")));

	// 차시별 서브영상 정보 세팅
	if(videoByLesson.containsKey(list.i("lesson_id"))) {
		DataSet videos = videoByLesson.get(list.i("lesson_id"));
		list.put("sub_video_cnt", videos.size());
		list.put("sub_video_block", videos.size() > 0);
		list.put(".sub_video_list", videos);
	} else {
		list.put("sub_video_cnt", 0);
		list.put("sub_video_block", false);
		// 왜: 템플릿이 이전 행의 loop 데이터를 재사용하지 않도록 빈 DataSet을 확실히 내려줍니다.
		list.put(".sub_video_list", new DataSet());
	}

	list.put("start_date_conv", m.time("yyyy-MM-dd", list.s("start_date")));
	list.put("end_date_conv", m.time("yyyy-MM-dd", list.s("end_date")));
	list.put("curr_chapter", list.i("chapter") * 1000);

	list.put("online_block", "N".equals(list.s("onoff_type")) || "T".equals(list.s("onoff_type")));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), lesson.onoffTypes));

	list.put("lesson_hour", list.s("lesson_hour").replace(".00", ""));

	list.put("start_time_hour", list.s("start_time").length() == 6 ? list.s("start_time").substring(0,2) : "");
	list.put("start_time_min", list.s("start_time").length() == 6 ? list.s("start_time").substring(2,4) : "");
	list.put("end_time_hour", list.s("end_time").length() == 6 ?  list.s("end_time").substring(0,2) : "");
	list.put("end_time_min", list.s("end_time").length() == 6 ? list.s("end_time").substring(2,4) : "");

	list.put("twoway_block", "15".equals(list.s("lesson_type")));
	list.put("empty_block", list.b("twoway_block") && (list.i("tutor_id") == 0 || list.s("start_date").length() != 8 || list.s("end_date").length() != 8 || list.s("start_time").length() != 6 || list.s("end_time").length() != 6));

	sortList.addRow();
	sortList.put("id", list.i("__asc"));
	sortList.put("name", list.i("__asc"));

	sidx[idx++] = list.i("section_id");

	if(lastSectionId != list.i("section_id") && 0 < list.i("section_id")) {
		lastSectionId = list.i("section_id");
		list.put("section_block", true);
	} else {
		list.put("section_block", false);
	}
}

if(1 > sidx.length || null == sidx) sidx = new Integer[] { 0 };

//목록-강사
DataSet tutors = courseTutor.query(
	"SELECT a.*, t.*, u.login_id "
	+ " FROM " + courseTutor.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON t.user_id = a.user_id "
	+ " INNER JOIN " + user.table + " u ON t.user_id = u.id "
	+ " WHERE a.course_id = " + cid + ""
);

//출력
p.setBody("course.course_lesson");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("cid,id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("course", cinfo);

p.setLoop("section_list", courseSection.find("id NOT IN (" + m.join(",", sidx) + ") AND course_id = " + cid + " AND status = 1"));
p.setLoop("sort_list", sortList);
p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes(5));
p.setLoop("tutors", tutors);

p.setVar("section_colspan", 3 + (cinfo.b("online_block") ? (cinfo.b("period_yn") ? 2 : 1) : 0) + ("B".equals(cinfo.s("onoff_type")) ? 1 : 0));
p.setVar("tab_lesson", "current");
p.display();

%>
