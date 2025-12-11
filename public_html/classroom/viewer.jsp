<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

response.addHeader("P3P","CP=\"IDC DSP COR ADM DEVi TAIi PSA PSD IVAi IVDi CONi HIS OUR IND CNT\"");

if("play".equals(m.rs("mode")) && m.isMobile()) {
	m.jsErrClose("새로고침을 하시면 학습창이 닫힙니다.");
	return;
}

//기본키
int lid = m.ri("lid");
int chapter = m.ri("chapter");
if(lid == 0) { m.jsErrClose(_message.get("alert.common.required_key")); return; }

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

//제한
if(1 != info.i("lesson_status")) { m.jsErrClose(_message.get("alert.lesson.stopped")); return; }

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

//목록-강의목차
DataSet list = courseLesson.query(
	"SELECT a.* "
	+ ", l.onoff_type, l.lesson_nm, l.start_url, l.mobile_a, l.mobile_i, l.lesson_type, l.total_time, l.total_page "
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
if(info.i("complete_time") == 0 && !"Y".equals(info.s("complete_yn"))) {
	info.put("complete_yn", "Y");
	info.put("last_time", info.i("total_time") * 60);
	info.put("p_ratio", "100.0");
	info.put("p_reg_date", m.time("yyyyMMddHHmmss"));
	courseProgress.completeProgress(cuid, lid, info.i("chapter"));
}

//진도정보가 없을 경우 초기화
if("".equals(info.s("p_reg_date"))) {
	courseProgress.initProgress(cuid, lid, info.i("course_id"), userId, info.i("chapter"), info.s("lesson_type"));
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
	int unixTime = m.getUnixTime();
	String key = lid + "|" + userId + "|" + unixTime;
	String startUrl = "/main/video.jsp?ek=" + m.encrypt(key) + "&lid=" + lid + "&uid=" + userId + "&ut=" + unixTime;
	if(info.s("start_url").endsWith(".m3u8")) fileType = "m3u8";
	else info.put("start_url", startUrl);
	info.put("start_url_conv", "/player/jwplayer.jsp?lid=" + lid + "&cuid=" + cuid + "&nid=" + info.s("next_lesson_id") + "&chapter=" + info.s("chapter") + "&ek=" + m.encrypt(lid + "|" + cuid + "|" + m.time("yyyyMMdd")));
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
p.setVar("iframe_block", "Y".equals(m.rs("iframe")) || "Y".equals(SiteConfig.s("kollus_iframe_yn")));

p.display();

%>