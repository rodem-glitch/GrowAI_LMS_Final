<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

response.addHeader("P3P","CP=\"IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT\"");

if("play".equals(m.rs("mode")) && m.isMobile()) {
	m.jsErrClose("새로고침을 하시면 학습창이 닫힙니다.");
	return;
}

//기본키
int lid = m.ri("lid");
int chapter = m.ri("chapter");
int vid = m.ri("vid"); //다중영상일 때 서브영상 id
// 왜: 구형 뷰어(버전 1)는 lid(강의 ID)가 없으면 진행/로그 처리가 불가능합니다.
//     신형 뷰어(버전 2)는 "바로학습" 등의 진입에서 lid 없이 들어올 수 있어, 아래에서 자동으로 차시를 선택합니다.
if(lid == 0 && sysViewerVersion != 2) { m.jsErrClose(_message.get("alert.common.required_key")); return; }

//객체
CourseLessonDao courseLesson = new CourseLessonDao();
CourseSectionDao courseSection = new CourseSectionDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId); courseProgress.setInsertIgnore(true);
CourseSessionDao courseSession = new CourseSessionDao(siteId);
LessonDao lesson = new LessonDao();
CourseUserLogDao courseUserLog = new CourseUserLogDao();
KollusDao kollus = new KollusDao(siteId);
DoczoomDao doczoom = new DoczoomDao();
FileDao file = new FileDao();
CourseLessonVideoDao courseLessonVideo = new CourseLessonVideoDao();
CourseProgressVideoDao courseProgressVideo = new CourseProgressVideoDao(siteId);

//제한-수강가능여부
if(0 < m.diffDate("D", cuinfo.s("restudy_edate"), today)) { m.jsErrClose(_message.get("alert.course_user.noperiod_study")); return; }

//변수
boolean limitFlag = false;
boolean isWait = "W".equals(cuinfo.s("progress"));
boolean isEnd = "E".equals(cuinfo.s("progress"));
boolean isOpen = true;
int lastChapter = 1;

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"lesson_"});

//바로학습
if(sysViewerVersion == 2 && lid == 0) {
	lid = cuinfo.i("llid"); //course_user_log의 마지막 lesson_id 를 가져옴
}

//목록
DataSet info = courseLesson.query(
	"SELECT a.* "
	+ ", l.onoff_type, l.lesson_nm, l.start_url, l.mobile_a, l.mobile_i, l.content_width, l.content_height, l.lesson_type, l.total_time, l.complete_time, l.description, l.status lesson_status, l.chat_yn, l.ai_chat_yn "
	+ ", p.curr_page, p.curr_time, p.last_time, p.study_time, p.ratio p_ratio, p.complete_yn, p.reg_date p_reg_date "
	+ ", ( CASE WHEN p.last_date BETWEEN '" + today + "000000' AND '" + today + "235959' THEN 'Y' ELSE 'N' END ) is_study"
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " LEFT JOIN " + courseProgress.table + " p ON p.course_user_id = " + cuid + " AND p.lesson_id = a.lesson_id "
	+ " WHERE a.status = 1 "
	+ " AND a.course_id = " + courseId
	+ ((sysViewerVersion == 2 && lid == 0)
		? " ORDER BY a.chapter ASC LIMIT 1 "
		: " AND a.lesson_id = " + lid + " "
	)
);
if(!info.next()) { m.jsErrClose(_message.get("alert.course_lesson.nodata")); return; }

// 왜: 신형 뷰어에서 lid 없이 들어온 경우(첫 학습 등)에도,
//     이후의 진도/로그/다중영상 조회가 모두 lesson_id 기준으로 정상 동작해야 합니다.
if(lid == 0) lid = info.i("lesson_id");

//제한
if(1 != info.i("lesson_status")) { m.jsErrClose(_message.get("alert.lesson.stopped")); return; }

// 다중 영상 차시에서는 아래에서 info에 "현재 재생할 영상" 정보를 덮어씁니다.
// 그래서 부모 차시(원래 차시)의 타입/완료여부는 따로 들고 있어야 안전합니다.
String parentLessonType = info.s("lesson_type");
String parentCompleteYN = info.s("complete_yn");

//다중영상 차시 여부 및 부모 합산시간 계산
//왜: 기존 단일차시 로직에 영향 없이, 다중영상으로 설정된 차시만 합산 시간/진도 기준을 적용하기 위해
boolean multiBlock = "Y".equals(info.s("multi_yn"))
	|| 0 < courseLessonVideo.findCount("course_id = " + courseId + " AND lesson_id = " + lid + " AND site_id = " + siteId + " AND status = 1");
int parentTotalMin = info.i("multi_total_time");
int parentCompleteMin = info.i("multi_complete_time");
if(multiBlock && (parentTotalMin == 0 && parentCompleteMin == 0)) {
	//캐시가 비어있으면 매핑 기준으로 다시 계산(운영 실수 대비)
	DataSet sums = courseLessonVideo.query(
		"SELECT SUM(l.total_time) total_time, SUM(l.complete_time) complete_time "
		+ " FROM " + courseLessonVideo.table + " v "
		+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 "
		+ " WHERE v.course_id = " + courseId + " AND v.lesson_id = " + lid + " AND v.site_id = " + siteId + " AND v.status = 1"
	);
	if(sums.next()) {
		parentTotalMin = sums.i("total_time");
		parentCompleteMin = sums.i("complete_time");
	}
}
if(multiBlock) {
	//부모 차시 기준 제한/배수/출결 계산을 위해 합산시간으로 치환
	info.put("total_time", parentTotalMin);
	info.put("complete_time", parentCompleteMin);
}

//포맷팅
info.put("lesson_nm_conv", m.cutString(info.s("lesson_nm"), 40));
info.put("description_conv", m.nl2br(info.s("description")));
info.put("image_url", m.getUploadUrl(cinfo.s("course_file")));
info.put("last_time", info.i("last_time"));
info.put("curr_time", info.i("curr_time"));
info.put("complete_block", "Y".equals(info.s("complete_yn")));
info.put("p_page", "Y".equals(info.s("complete_yn")) ? "" : info.s("curr_page"));	//시작페이지
info.put("start_pos", 100 <= info.d("p_ratio") ? 0 : info.i("last_time"));		//시작타임
info.put("catenoid_block", "05".equals(info.s("lesson_type")));
info.put("p_ratio", info.d("p_ratio"));
info.put("content_height_conv", info.i("content_height") + 20);

//학습제한-속진여부
limitFlag = (cinfo.b("limit_lesson_yn") ? limitFlag = courseProgress.getLimitFlag(cuid, cinfo) : false);
lastChapter = 1 + courseProgress.findCount("course_user_id = " + cuid + " AND complete_yn = 'Y' AND chapter <= " + info.i("chapter"));

if(isOpen && limitFlag) { //속진제한
	isOpen = "Y".equals(info.s("is_study"));
	info.put("msg", _message.get("alert.classroom.limit_study", new String[] {"limit_day=>1", "limit_lesson=>" + cinfo.i("limit_lesson")}));
}
if(isOpen && cinfo.b("period_yn")) { //수강기간 제한
//	isOpen = info.i("start_date") <= m.parseInt(today) && (cinfo.b("restudy_yn") || info.i("end_date") >= m.parseInt(today));
	String startDateTime = info.s("start_date") + (info.s("start_time").length() == 6 ? info.s("start_time") : "000000");
	String endDateTime = info.s("end_date") + (info.s("end_time").length() == 6 ? info.s("end_time") : "235959");
	long nowDateTime = Malgn.parseLong(now);

	isOpen = Malgn.parseLong(startDateTime) <= nowDateTime && (Malgn.parseLong(endDateTime) >= nowDateTime);

	info.put("msg", _message.get("alert.classroom.noperiod_study"));
}
if(isOpen && cinfo.b("lesson_order_yn")) { //순차적용
	isOpen = lastChapter >= info.i("chapter");
	info.put("msg", _message.get("alert.classroom.order_study", new String[] {"chapter=>" + (info.i("chapter") - 1)}));
}

if("Y".equals(info.s("complete_yn"))) isOpen = true;


if(cinfo.b("limit_ratio_yn") && (info.i("total_time") * 60 * cinfo.d("limit_ratio") < info.d("study_time"))) { //배수제한
	//total_time * limit_ratio < study_time
	isOpen = false;
	info.put("msg", _message.get("alert.classroom.over_study"));
}


if(isEnd || isWait) { //수강 대기, 종료
	isOpen = false;
	info.put("msg", _message.get("alert.classroom.noperiod_course"));
}
info.put("open_block", isOpen);
info.put("on_block", info.i("chapter") == chapter);

if(!isOpen) {
	m.jsErrClose(info.s("msg")); return;
}

//SMS인증
if(info.d("p_ratio") < 100.0 && cuinfo.b("sms_yn") && !courseSession.verifySession(cuid, lid, userSessionId)) {
	m.jsReplace("../classroom/sms_auth.jsp?" + m.qs());
	return;
}

//다중영상 차시일 경우: 서브영상 목록을 불러오고, 현재 재생할 서브영상을 결정합니다.
DataSet videoList = new DataSet();
int currentVid = 0;
int nextVid = 0;
if(multiBlock) {
	videoList = courseLessonVideo.query(
		"SELECT v.video_id, v.sort "
		+ ", l.lesson_nm, l.lesson_type, l.start_url, l.mobile_a, l.mobile_i, l.content_width, l.content_height, l.total_time, l.complete_time, l.description "
		+ ", p.curr_time, p.last_time, p.study_time, p.ratio p_ratio, p.complete_yn "
		+ " FROM " + courseLessonVideo.table + " v "
		+ " INNER JOIN " + lesson.table + " l ON l.id = v.video_id AND l.status = 1 "
		+ " LEFT JOIN " + courseProgressVideo.table + " p ON p.course_user_id = " + cuid + " AND p.lesson_id = " + lid + " AND p.video_id = v.video_id AND p.status = 1 "
		+ " WHERE v.course_id = " + courseId
		+ " AND v.lesson_id = " + lid
		+ " AND v.site_id = " + siteId
		+ " AND v.status = 1 "
		+ " ORDER BY v.sort ASC "
	);

	//현재 서브영상 선택 규칙
	// 1) vid 파라미터가 있으면 그 영상
	// 2) 없으면 미완료(complete_yn != Y) 중 첫 번째
	// 3) 모두 완료면 첫 번째
	currentVid = vid;
	boolean found = false;
	if(currentVid > 0) {
		videoList.first();
		while(videoList.next()) {
			if(videoList.i("video_id") == currentVid) { found = true; break; }
		}
	}
	if(currentVid == 0 || !found) {
		currentVid = 0;
		videoList.first();
		while(videoList.next()) {
			if(!"Y".equals(videoList.s("complete_yn"))) { currentVid = videoList.i("video_id"); break; }
		}
		if(currentVid == 0 && videoList.size() > 0) {
			videoList.first(); videoList.next();
			currentVid = videoList.i("video_id");
		}
	}

	//다음 서브영상(선택 표시용)
	videoList.first();
	boolean passedCurrent = false;
	while(videoList.next()) {
		if(passedCurrent) { nextVid = videoList.i("video_id"); break; }
		if(videoList.i("video_id") == currentVid) passedCurrent = true;
	}

	//서브영상 목록 포맷팅 + 재생 URL 세팅
	videoList.first();
	while(videoList.next()) {
		videoList.put("lesson_nm_conv", m.cutString(videoList.s("lesson_nm"), 40));
		videoList.put("study_min", videoList.i("study_time") / 60);
		videoList.put("complete_block", "Y".equals(videoList.s("complete_yn")));
		videoList.put("on_block", videoList.i("video_id") == currentVid);
		videoList.put("play_url", "viewer.jsp?" + m.qs("vid") + "&vid=" + videoList.i("video_id"));
	}

	//현재 재생할 서브영상 정보로 info를 덮어씁니다.
	DataSet playInfo = lesson.query(
		"SELECT a.* "
		+ ", p.curr_time, p.last_time, p.study_time, p.ratio p_ratio, p.complete_yn "
		+ " FROM " + lesson.table + " a "
		+ " LEFT JOIN " + courseProgressVideo.table + " p ON p.course_user_id = " + cuid + " AND p.lesson_id = " + lid + " AND p.video_id = a.id AND p.status = 1 "
		+ " WHERE a.id = " + currentVid + " AND a.status = 1 "
	);
	if(!playInfo.next()) { m.jsErrClose("서브영상 정보를 찾을 수 없습니다."); return; }

	info.put("video_id", currentVid);
	info.put("lesson_nm", playInfo.s("lesson_nm"));
	info.put("lesson_type", playInfo.s("lesson_type"));
	info.put("start_url", playInfo.s("start_url"));
	info.put("mobile_a", playInfo.s("mobile_a"));
	info.put("mobile_i", playInfo.s("mobile_i"));
	info.put("content_width", playInfo.i("content_width"));
	info.put("content_height", playInfo.i("content_height"));
	info.put("description", playInfo.s("description"));
	info.put("total_time", playInfo.i("total_time"));
	info.put("complete_time", playInfo.i("complete_time"));
	info.put("curr_time", playInfo.i("curr_time"));
	info.put("last_time", playInfo.i("last_time"));
	info.put("study_time", playInfo.i("study_time"));
	info.put("p_ratio", playInfo.d("p_ratio"));
	info.put("complete_yn", playInfo.s("complete_yn"));

	//현재 재생 서브영상 기준으로 다시 포맷팅
	info.put("lesson_nm_conv", m.cutString(info.s("lesson_nm"), 40));
	info.put("description_conv", m.nl2br(info.s("description")));
	info.put("complete_block", "Y".equals(info.s("complete_yn")));
	info.put("start_pos", 100 <= info.d("p_ratio") ? 0 : info.i("last_time"));
	info.put("catenoid_block", "05".equals(info.s("lesson_type")));
	info.put("content_height_conv", info.i("content_height") + 20);
}

//목록-강의목차
DataSet list = courseLesson.query(
	"SELECT a.* "
	+ ", l.onoff_type, l.lesson_nm, l.start_url, l.mobile_a, l.mobile_i, l.lesson_type, l.total_time, l.complete_time, l.total_page "
	+ ", c.complete_yn, c.ratio, c.last_date, c.study_time, c.study_page "
	+ ", cs.id section_id, cs.section_nm "
	+ ", ( CASE WHEN c.last_date BETWEEN '" + today + "000000' AND '" + today + "235959' THEN 'Y' ELSE 'N' END ) is_study "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.onoff_type != 'F'"
	+ " LEFT JOIN " + courseProgress.table + " c ON c.course_user_id = " + cuid + " AND c.lesson_id = a.lesson_id "
	+ " LEFT JOIN " + courseSection.table + " cs ON a.section_id = cs.id AND a.course_id = cs.course_id AND cs.status = 1 "
	+ " WHERE a.status = 1 AND a.course_id = " + courseId + " "
	+ " ORDER BY a.chapter ASC "
);
int maxChapter = 0;
lastChapter = 1;
int lastSectionId = 0;
boolean noSectionBlock = false;
while(list.next()) {
	//다중영상 차시는 과정-차시 테이블의 합산시간을 사용
	if("Y".equals(list.s("multi_yn"))) {
		if(list.i("multi_total_time") > 0) list.put("total_time", list.i("multi_total_time"));
		if(list.i("multi_complete_time") > 0) list.put("complete_time", list.i("multi_complete_time"));
	}
	if(list.i("chapter") > maxChapter) maxChapter = list.i("chapter");
	if(list.b("complete_yn")) lastChapter = list.i("chapter") + 1;
	list.put("study_min", list.i("study_time") / 60);
	list.put("study_page", list.i("study_page"));
	list.put("lesson_nm_conv", m.cutString(list.s("lesson_nm"), 50));

	list.put("ratio_conv", m.nf(list.d("ratio"), 0));

	if("N".equals(list.s("onoff_type"))) list.put("online_block", true);
	else if("F".equals(list.s("onoff_type"))) list.put("online_block", false);

	isOpen = true;

	if(isOpen && limitFlag) { //속진제한
		isOpen = "Y".equals(list.s("is_study"));
		list.put("msg", _message.get("alert.classroom.limit_study", new String[] {"limit_day=>1", "limit_lesson=>" + cinfo.i("limit_lesson")}));
	}
	if(isOpen && cinfo.b("period_yn")) { //수강기간 제한
		isOpen = list.i("start_date") <= m.parseInt(today) && (cinfo.b("restudy_yn") || list.i("end_date") >= m.parseInt(today));
		list.put("msg", _message.get("alert.classroom.noperiod_study"));
	}
	if(isOpen && cinfo.b("lesson_order_yn")) { //순차적용
		isOpen = lastChapter >= list.i("chapter");
		list.put("msg", _message.get("alert.classroom.order_study", new String[] {"chapter=>" + (list.i("chapter") - 1)}));
	}

	if("Y".equals(list.s("complete_yn"))) isOpen = true;

	if(isEnd || isWait) { //수강 대기, 종료
		isOpen = false;
		list.put("msg", _message.get("alert.classroom.noperiod_course"));
	}
	list.put("open_block", isOpen);
	list.put("on_block", list.i("chapter") == chapter);
	if(list.i("chapter") == (chapter + 1)) {
		info.put("next_lesson_nm_conv", list.s("lesson_nm_conv"));
		info.put("next_lesson_id", list.s("lesson_id"));
		info.put("next_chapter", list.s("chapter"));
	}

	if(lastSectionId != list.i("section_id") && 0 < list.i("section_id")) {
		lastSectionId = list.i("section_id");
		list.put("section_block", true);
	} else {
		list.put("section_block", false);
		if(list.i("__ord") == 1) noSectionBlock = true;
	}

	if(list.i("lesson_id") == lid) list.put("lesson_status", "N"); // 현재시청중
	else if("Y".equals(list.s("complete_yn"))) list.put("lesson_status", "C"); // 수강완료
	else if("N".equals(list.s("complete_yn"))) list.put("lesson_status", "I"); //수강중
	else list.put("lesson_status", "W"); //미수강
}

//집합과정
if("F".equals(info.s("onoff_type")) && 10 < info.i("lesson_type")) {
	//기본키
	String k = m.rs("k");
	String ek = m.rs("ek");
	if("".equals(k) || "".equals(ek)) { m.jsErrClose(_message.get("alert.common.required_key")); return; }

	k = SimpleAES.decrypt(m.decode(k));
	String eKey = m.encrypt("CLASSROOM_" + info.s("course_id") + "_CHAPTER_" + chapter + "_ATTEND_" + k);
	if(!eKey.equals(ek)) { m.jsAlert(_message.get("alert.common.abnormal_access"));	return; }

	//제한-시간
	int gap = m.diffDate("I", k, m.time("yyyyMMddHHmmss"));
	if(gap > 10) { m.jsErrClose("유효기간이 지났습니다."); return; }

	//제한-기출석
	if(info.b("complete_yn")) { m.jsErrClose("이미 출석한 차시입니다."); return; }

	//처리
	info.put("complete_yn", "Y");
	info.put("last_time", info.i("total_time") * 60);
	info.put("p_ratio", "100.0");
	info.put("p_reg_date", m.time("yyyyMMddHHmmss"));
	courseProgress.completeProgress(cuid, lid, info.i("chapter"));

	//이동
	m.jsAlert("출석처리되었습니다.");
	m.jsReplace("../classroom/index.jsp?cuid=" + cuid);
	return;
}

//인정시간이 0인 경우 곧바로 완료처리
// - 단일 영상 차시: 해당 차시 complete_time(분) == 0 이면 즉시 완료
// - 다중 영상 차시: 합산 complete_time(분) == 0 이면 즉시 완료
int parentCompleteTimeMinForAutoComplete = multiBlock ? parentCompleteMin : info.i("complete_time");
String parentCompleteYNForAutoComplete = multiBlock ? parentCompleteYN : info.s("complete_yn");
if(parentCompleteTimeMinForAutoComplete == 0 && !"Y".equals(parentCompleteYNForAutoComplete)) {
	// 단일 영상 차시에서는 기존 화면 변수를 그대로 맞춰주고,
	// 다중 영상 차시에서는 "현재 영상" 변수(info)가 덮어써져 있으므로 DB만 정확히 갱신합니다.
	if(!multiBlock) {
		info.put("complete_yn", "Y");
		info.put("last_time", info.i("total_time") * 60);
		info.put("p_ratio", "100.0");
		info.put("p_reg_date", m.time("yyyyMMddHHmmss"));
	}
	courseProgress.completeProgress(cuid, lid, info.i("chapter"));
	parentCompleteYN = "Y";
}

//진도정보가 없을 경우 초기화
if("".equals(info.s("p_reg_date"))) {
	// 부모 차시 진도는 "부모 차시의 타입"으로 만들어야 이후 통계/표시가 꼬이지 않습니다.
	courseProgress.initProgress(cuid, lid, info.i("course_id"), userId, info.i("chapter"), parentLessonType);
}

//로그
courseUserLog.item("course_user_id", cuinfo.i("id"));
courseUserLog.item("user_id", userId);
//courseUserLog.item("user_nm", userName);
courseUserLog.item("course_id", cuinfo.s("course_id"));
//courseUserLog.item("course_nm", cuinfo.s("course_nm"));
//courseUserLog.item("start_date", cuinfo.s("start_date"));
//courseUserLog.item("end_date", cuinfo.s("end_date"));
courseUserLog.item("chapter", info.i("chapter"));
courseUserLog.item("lesson_id", info.i("lesson_id"));
//courseUserLog.item("lesson_nm", info.s("lesson_nm"));
courseUserLog.item("progress_ratio", info.d("p_ratio"));
courseUserLog.item("progress_complte_yn", !"".equals(info.s("complete_yn")) ? info.s("complete_yn") : "N");
courseUserLog.item("user_ip_addr", userIp);
courseUserLog.item("user_agent", courseUserLog.getBrowser(request.getHeader("user-agent")));
courseUserLog.item("reg_date", m.time("yyyyMMddHHmmss"));
courseUserLog.item("status", 1);
courseUserLog.item("site_id", siteId);
if(!courseUserLog.insert()) { }

DataSet files = file.getFileList(info.i("lesson_id"), "lesson");
DataSet pdf = new DataSet();
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id") + m.time("yyyyMMdd")));
	files.put("cek", m.encrypt(cuid + files.s("id") + info.s("lesson_id") + m.time("yyyyMMdd")));
	files.put("sep", !files.b("__last") ? "<br>" : "");
	files.put("filesize_conv", file.getFileSize(files.l("filesize")));

	//가장 처음 pdf 교안파일을 pdf 영역으로 사용
	if(pdf.isEmpty() && "pdf".equals(files.s("file_ext"))) {
		pdf.addRow(files.getRow());
		pdf.put("url", m.getUploadUrl(pdf.s("filename")));
	}
}

//OTU만료시간
if(!"".equals(SiteConfig.s("kollus_expire_time")) && !"0".equals(SiteConfig.s("kollus_expire_time"))) {
	kollus.setExpireTime(SiteConfig.i("kollus_expire_time"));
}

//동영상경로보안
//kollus.d(out);
String fileType = "mp4";
if("01".equals(info.s("lesson_type")) || "03".equals(info.s("lesson_type"))) {
	//다중영상일 때는 현재 서브영상 id로 플레이어를 호출합니다.
	int playLid = multiBlock ? currentVid : lid;
	// 왜: 다중영상에서 “다음 영상 자동재생”을 구현하려면, 플레이어가 다음 서브영상 id도 알아야 합니다.
	//     또한 PC에서는 자동으로 넘어가되, 모바일은 자동재생 제한이 있을 수 있어 autoplay 플래그로 제어합니다.
	String autoplayYn = "Y".equals(m.rs("autoplay")) ? "Y" : "N";
	int unixTime = m.getUnixTime();
	String key = playLid + "|" + userId + "|" + unixTime;
	String startUrl = "/main/video.jsp?ek=" + m.encrypt(key) + "&lid=" + playLid + "&uid=" + userId + "&ut=" + unixTime;
	if(info.s("start_url").endsWith(".m3u8")) fileType = "m3u8";
	else info.put("start_url", startUrl);
	info.put("start_url_conv", "/player/jwplayer.jsp?lid=" + playLid
		+ "&plid=" + lid
		+ "&cuid=" + cuid
		+ "&nid=" + info.s("next_lesson_id")
		+ "&chapter=" + info.s("chapter")
		+ "&vid=" + (multiBlock ? playLid : 0)
		+ "&nvid=" + (multiBlock ? nextVid : 0)
		+ "&autoplay=" + autoplayYn
		+ "&ek=" + m.encrypt(playLid + "|" + cuid + "|" + m.time("yyyyMMdd")));
} else if("05".equals(info.s("lesson_type"))) {
	//kollus.d(out);
	String startUrl = kollus.getPlayUrl(
			info.s("start_url")
			, "" + siteId + "_" + loginId, (info.b("complete_yn") || !cuinfo.b("limit_seek_yn"))
			, !("Y".equals(SiteConfig.s("kollus_playrate_yn")) && !"Y".equals(cinfo.s("playrate_yn")))
			, info.i("last_time"));
	//m.jsAlert(m.getUnixTime() + SiteConfig.i("kollus_expire_time") + " / " + SiteConfig.i("kollus_expire_time"));
	p.setVar("leave_block", 0 < siteconfig.i("lesson_detect_leave_min") && !"".equals(siteconfig.s("lesson_detect_leave_min")));
	if("https".equals(request.getScheme())) startUrl = startUrl.replace("http://", "https://");
	if("Y".equals(m.rs("download"))) {
		startUrl += "&download";
		p.setVar("download_block", true);
		p.setVar("leave_block", false);
	}
	info.put("download_url", m.replace(startUrl, "//v.kr.kollus.com/s?", "//v.kr.kollus.com/si?"));
	info.put("start_url", startUrl);
	info.put("start_url_conv", startUrl);

} else if("07".equals(info.s("lesson_type"))) {
	//kollus.d(out);
	String startUrl = kollus.getLiveUrl(info.s("start_url"), "" + siteId + "_" + loginId) + "&custom_key=" + SiteConfig.s("kollus_live_custom_key");
	if("https".equals(request.getScheme())) startUrl = startUrl.replace("http://", "https://");
	info.put("start_url", startUrl);
	info.put("start_url_conv", startUrl);

} else if("04".equals(info.s("lesson_type"))) {
	if(info.s("start_url").indexOf("youtube.com") > 0) {
		boolean qmark = info.s("start_url").indexOf("?") > 0;
		info.put("start_url", info.s("start_url") + (qmark ? "&" : "?") + "enablejsapi=1");
	} else if(info.s("start_url").indexOf("zoom.us") > 0) {
		p.setVar("zoom_block", true);
	} else if(info.s("start_url").contains("teams.microsoft.com") || info.s("start_url").contains("remotemeeting.com")) {
		m.redirect(info.s("start_url"));
		return;
	}

} else if("06".equals(info.s("lesson_type"))) {
	String contentID = info.s("start_url");
	String userID = "malgn_" + siteinfo.s("ftp_id");
	String startUrl = "https://cms.malgnlms.com/DocZoomMobile/doczoomviewer.asp?MediaID=" + contentID;
	//String startUrl = "https://cms.malgnlms.com/DocZoomManagementServer/DocZoomManager/ViewDocZoom.aspx?doczoomID=" + contentID;

	DataSet dinfo = doczoom.getContentInfo(contentID);
	if(dinfo.next()) {
		String SessionID = doczoom.addContentViewerLoginSharedSessionData(userID, contentID, 10);
		if(SessionID != null) {
			startUrl += "&sessionID=" + SessionID;
			info.put("start_url", startUrl);
			info.put("start_url_conv", startUrl);
		} else {
			m.jsErrClose("세션값을 가지오지 못했습니다."); return;
		}
	} else {
		m.jsErrClose("문서 정보를 조회할 수 없습니다."); return;
	}
}

//채팅
if(siteconfig.b("lesson_chat_yn") && "Y".equals(info.s("chat_yn"))) {
//	p.setVar("chat_block", true);
	p.setVar("chat_block", false); //미니톡 사용중지 - 20230907
	p.setVar("mid", courseId);
	p.setVar("chat_mode", "c");
}

//AI 채팅
if("Y".equals(SiteConfig.s("sys_ai_chat_yn")) && sysViewerVersion == 2 && info.b("ai_chat_yn")) {
	p.setVar("ai_block", true);
}

//갱신-일회용아이디
if(!siteinfo.b("duplication_yn")) {
	String otid = m.getUniqId();
	if(!courseSession.updateOnetime(userId, 0, otid)) {
		m.jsErrClose(_message.get("alert.classroom.error_lesson"));
		return;
	}
	p.setVar("otid", otid);
}

String bodyType = Malgn.getItem(info.s("lesson_type"), lesson.htmlTypes);

//출력
p.setLayout(sysViewerVersion == 2 ? "viewer" : null);
p.setBody("classroom.viewer_" + bodyType);
p.setVar("is_lesson", "lesson".equals(bodyType));

p.setVar(info);
p.setVar("lesson_query", m.qs("lid,chapter"));

//다중영상 관련 변수
p.setVar("multi_block", multiBlock);
p.setVar("current_vid", currentVid);
p.setVar("next_vid", nextVid);
p.setVar("next_vid_block", nextVid > 0);
p.setVar("next_video_url", nextVid > 0 ? ("viewer.jsp?" + m.qs("vid, autoplay") + "&vid=" + nextVid) : "");
p.setVar("next_video_autoplay_url", nextVid > 0 ? ("viewer.jsp?" + m.qs("vid, autoplay") + "&vid=" + nextVid + "&autoplay=Y") : "");
p.setVar("video_id", currentVid);
p.setVar("parent_total_time", parentTotalMin);
p.setVar("parent_complete_time", parentCompleteMin);
p.setLoop("video_list", videoList);

p.setLoop("list", list);
p.setLoop("files", files);

p.setVar("pdf", pdf);
p.setVar("site_config", siteconfig);

p.setVar("lid", lid);
p.setVar("file_type", fileType);
p.setVar("pdf_block", !pdf.isEmpty());
p.setVar("file_block", files.size() > 0);
p.setVar("no_section_block", noSectionBlock);
p.setVar("is_max", info.i("chapter") == maxChapter);
p.setVar("no_list_block", list.size() == 0);

//왜: 콜러스(외부 플레이어) 화면을 “리다이렉트로만” 열면,
//    우리 화면이 사라져서 서브영상 완료 후 다음 영상으로 넘어갈 수 없습니다.
//    다중영상 차시에서는 반드시 iframe 기반으로 열어, 이어보기(자동/버튼)를 할 수 있게 합니다.
boolean iframeBlock = "Y".equals(m.rs("iframe")) || "Y".equals(SiteConfig.s("kollus_iframe_yn"));
if(multiBlock && ("05".equals(info.s("lesson_type")) || "07".equals(info.s("lesson_type")))) iframeBlock = true;
p.setVar("iframe_block", iframeBlock);

p.display();

%>
