<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if("".equals(userId)) { m.redirect("login.jsp"); return; }

//기본키
int cuid = m.ri("cuid");
if(cuid == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
UserDao user = new UserDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseModuleDao courseModule = new CourseModuleDao();
CourseSessionDao courseSession = new CourseSessionDao(siteId);
SmsDao sms = new SmsDao(siteId);
sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

//변수
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");

//정보
DataSet cuinfo = courseUser.query(
	"SELECT a.*, c.course_nm, c.course_type, c.onoff_type, c.sms_yn, c.limit_seek_yn, t.user_nm tutor_name, c.subject_id, u.id user_id, u.user_nm, u.mobile "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " AND c.mobile_yn = 'Y' "
	+ " LEFT JOIN " + user.table + " t ON a.tutor_id = t.id"
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id"
	+ " WHERE a.id = " + cuid + " AND a.user_id = '" + userId + "' AND a.status IN (1,3)"
);
if(!cuinfo.next()) { m.jsError(_message.get("alert.course_user.nodata")); return; }

//정보-과정
String courseId = cuinfo.s("course_id");
DataSet cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + "");
if(!cinfo.next()) { m.jsError(_message.get("alert.course.nodata")); return; }
cinfo.put("onoff_type_conv", m.getItem(cinfo.s("onoff_type"), course.onoffTypes));
cinfo.put("std_progress", m.nf(cinfo.i("assign_progress") * cinfo.i("limit_progress") / 100, 1));
cinfo.put("std_exam", m.nf(cinfo.i("assign_exam") * cinfo.i("limit_exam") / 100, 1));
cinfo.put("std_homework", m.nf(cinfo.i("assign_homework") * cinfo.i("limit_homework") / 100, 1));
cinfo.put("std_forum", m.nf(cinfo.i("assign_forum") * cinfo.i("limit_forum") / 100, 1));
cinfo.put("std_etc", m.nf(cinfo.i("assign_etc") * cinfo.i("limit_etc") / 100, 1));

boolean alltime = "A".equals(cuinfo.s("course_type"));
cinfo.put("alltime_block", alltime);

//상태 [progress] (W : 대기, E : 종료, I : 수강중, R : 복습중)
cuinfo.put("restudy_edate", cuinfo.s("end_date"));
cuinfo.put("restudy_block", false);
String progress = "I";
if(0 > m.diffDate("D", cuinfo.s("start_date"), today)) progress = "W"; //대기
else if(0 >= m.diffDate("D", cuinfo.s("end_date"), today)) progress = "I"; //수강중
else {
	if(cinfo.b("restudy_yn")) {  //복습
		progress = "R";
		cuinfo.put("restudy_edate", m.addDate("D", cinfo.i("restudy_day"), cuinfo.s("end_date"), "yyyyMMdd"));
		cuinfo.put("restudy_block", true);
	} else progress = "E"; //종료
}
cuinfo.put("restudy_edate_conv", m.time(_message.get("format.date.dot"), cuinfo.s("restudy_edate")));
cuinfo.put("progress", progress);
cuinfo.put("status_conv", m.getItem(progress, courseUser.progressList));
if("Y".equals(cuinfo.s("close_yn"))) cuinfo.put("status_conv", "마감");

cuinfo.put("tutor_name", !"".equals(cuinfo.s("tutor_name")) ? cuinfo.s("tutor_name") : "-");
cuinfo.put("start_date_conv", m.time(_message.get("format.date.dot"), cuinfo.s("start_date")));
cuinfo.put("end_date_conv", m.time(_message.get("format.date.dot"), cuinfo.s("end_date")));
cuinfo.put("past_day", m.diffDate("D", cuinfo.s("start_date"), today));  //경과일

cuinfo.put("total_score_conv", m.nf(cuinfo.d("total_score"), 1));
cuinfo.put("progress_ratio_conv", m.nf(cuinfo.d("progress_ratio"), 1));
cuinfo.put("exam_value_conv", m.nf(cuinfo.d("exam_value"), 1));
cuinfo.put("homework_value_conv", m.nf(cuinfo.d("homework_value"), 1));
cuinfo.put("forum_value_conv", m.nf(cuinfo.d("forum_value"), 1));
cuinfo.put("etc_value_conv", m.nf(cuinfo.d("etc_value"), 1));

cuinfo.put("progress_score_conv", m.nf(cuinfo.d("progress_score"), 1));
cuinfo.put("exam_score_conv", m.nf(cuinfo.d("exam_score"), 1));
cuinfo.put("homework_score_conv", m.nf(cuinfo.d("homework_score"), 1));
cuinfo.put("forum_score_conv", m.nf(cuinfo.d("forum_score"), 1));
cuinfo.put("etc_score_conv", m.nf(cuinfo.d("etc_score"), 1));

p.setVar("cuinfo", cuinfo);
p.setVar("course", cinfo);

//기본키
int lid = m.ri("lid");
int chapter = m.ri("chapter");
if(lid == 0 || chapter == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
CourseLessonDao courseLesson = new CourseLessonDao();
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
LessonDao lesson = new LessonDao();
CourseUserLogDao courseUserLog = new CourseUserLogDao();
KollusDao kollus = new KollusDao(siteId);
DoczoomDao doczoom = new DoczoomDao();

//제한-수강가능여부
if(0 < m.diffDate("D", cuinfo.s("restudy_edate"), today)) { m.jsError(_message.get("alert.course_user.noperiod_study")); return; }

//변수
boolean limitFlag = false;
boolean isWait = "W".equals(cuinfo.s("progress"));
boolean isEnd = "E".equals(cuinfo.s("progress"));
boolean isOpen = true;
int lastChapter = 1;

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"lesson_"});

//목록
DataSet info = courseLesson.query(
	"SELECT a.* "
	+ ", l.lesson_nm, l.start_url, l.mobile_a, l.mobile_i, l.content_width, l.content_height, l.lesson_type, l.total_time, l.complete_time, l.description, l.status lesson_status, l.chat_yn "
	+ ", p.curr_page, p.curr_time, p.last_time, p.study_time, p.ratio p_ratio, p.complete_yn, p.reg_date p_reg_date "
	+ ", ( CASE WHEN p.last_date BETWEEN '" + today + "000000' AND '" + today + "235959' THEN 'Y' ELSE 'N' END ) is_study"
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
	+ " LEFT JOIN " + courseProgress.table + " p ON p.course_user_id = " + cuid + " AND p.lesson_id = a.lesson_id "
	+ " WHERE a.status = 1 "
	+ " AND a.course_id = " + courseId
	+ " AND a.lesson_id = " + lid
);
if(!info.next()) { m.jsError(_message.get("alert.course_lesson.nodata")); return; }

//제한
if(1 != info.i("lesson_status")) { m.jsError(_message.get("alert.lesson.stopped")); return; }

//SMS인증
if(info.d("p_ratio") < 100.0 && cuinfo.b("sms_yn") && !courseSession.verifySession(cuid, lid, userSessionId)) {
	m.jsReplace("../mobile/sms_auth.jsp?" + m.qs());
	return;
}

//인정시간이 0인 경우 곧바로 완료처리
if(info.i("complete_time") == 0 && !"Y".equals(info.s("complete_yn"))) {
	info.put("complete_yn", "Y");
	info.put("last_time", info.i("total_time") * 60);
	info.put("p_ratio", "100.0");
	info.put("p_reg_date", m.time("yyyyMMddHHmmss"));
	info.put("image_url", m.getUploadUrl(cinfo.s("course_file")));
	courseProgress.completeProgress(cuid, lid, chapter);
}

//진도로그가 없는 경우 초기화
if("".equals(info.s("p_reg_date"))) {
	courseProgress.initProgress(cuid, lid, info.i("course_id"), userId, info.i("chapter"), info.s("lesson_type"));
}

info.put("p_ratio", info.d("p_ratio"));
info.put("last_time", info.i("last_time"));
info.put("curr_time", info.i("curr_time"));
info.put("complete_block", "Y".equals(info.s("complete_yn")));
info.put("p_page", "Y".equals(info.s("complete_yn")) ? "" : info.s("curr_page"));	//시작페이지
info.put("start_pos", 100 <= info.d("p_ratio") ? 0 : info.i("last_time"));		//시작타임
info.put("catenoid_block", "05".equals(info.s("lesson_type")));

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

//목록-강의목차
DataSet list = courseLesson.query(
	"SELECT a.* "
	+ ", l.onoff_type, l.lesson_nm, l.start_url, l.mobile_a, l.mobile_i, l.lesson_type, c.complete_yn, c.ratio, c.last_date "
	+ ", ( CASE WHEN c.last_date BETWEEN '" + today + "000000' AND '" + today + "235959' THEN 'Y' ELSE 'N' END ) is_study "
	+ " FROM " + courseLesson.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id " //+ ("W".equals(siteinfo.s("ovp_vendor")) ? " AND l.lesson_type != '05' " : " AND l.lesson_type != '01' ")
	+ " LEFT JOIN " + courseProgress.table + " c ON c.course_user_id = " + cuid + " AND c.lesson_id = a.lesson_id "
	+ " WHERE a.status = 1 AND a.course_id = " + courseId + " "
	+ " ORDER BY a.chapter ASC "
);
int maxChapter = 0;
lastChapter = 1;
while(list.next()) {
	if(list.i("chapter") > maxChapter) maxChapter = list.i("chapter");
	if(list.b("complete_yn")) lastChapter = list.i("chapter") + 1;
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
	list.put("next_block", list.i("chapter") == (chapter + 1));
}

String fileType = "mp4";

//동영상경로보안
if(m.isMobile() && !"".equals(info.s("mobile_a")) && !info.s("start_url").equals(info.s("mobile_a"))) {
	info.put("start_url", info.s("mobile_a"));
	if(info.s("mobile_a").indexOf(".mp4") > 0 || info.s("mobile_a").indexOf(".m3u8") > 0) {
		if("02".equals(info.s("lesson_type"))) info.put("lesson_type", "03");
	}
}

if("01".equals(info.s("lesson_type")) || "03".equals(info.s("lesson_type"))) {
    int unixTime = m.getUnixTime();
    String key = lid + "|" + userId + "|" + unixTime;
    String startUrl = "/main/video.jsp?ek=" + m.encrypt(key) + "&lid=" + lid + "&uid=" + userId + "&ut=" + unixTime;
	if(info.s("start_url").endsWith(".m3u8")) fileType = "m3u8";
	else info.put("start_url", startUrl);
	info.put("start_url_conv", "/player/jwplayer.jsp?lid=" + lid + "&cuid=" + cuid + "&chapter=" + info.s("chapter") + "&ek=" + m.encrypt(lid + "|" + cuid + "|" + m.time("yyyyMMdd")));
} else if("05".equals(info.s("lesson_type"))) {
	String startUrl = kollus.getPlayUrl(
			info.s("start_url")
			, "" + siteId + "_" + loginId
			, (info.b("complete_yn") || !cuinfo.b("limit_seek_yn"))
			, !("Y".equals(SiteConfig.s("kollus_playrate_yn")) && !"Y".equals(cinfo.s("playrate_yn")))
			, info.i("last_time"));
	if("https".equals(request.getScheme())) startUrl = startUrl.replace("http://", "https://");
	if("download".equals(m.rs("type"))) startUrl += "&download";
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
			m.jsError("세션값을 가지오지 못했습니다."); return;
		}
	} else {
		m.jsError("문서 정보를 조회할 수 없습니다."); return;
	}
}

//채팅
if(siteconfig.b("lesson_chat_yn") && "Y".equals(info.s("chat_yn"))) {
	info.put("channel", lesson.getChannelId(siteinfo.s("ftp_id"), siteId, info.i("course_id"), info.i("lesson_id"), "c"));
	info.put("nickname", userName);
	info.put("chat_block", true);
}

//갱신-일회용아이디
String otid = m.getUniqId();
if(!courseSession.updateOnetime(cuid, lid, otid)) {
	m.jsError(_message.get("alert.classroom.error_lesson"));
	return;
}

//출력
p.setLayout(null);
p.setBody("mobile.viewer_" + m.getItem(info.s("lesson_type"), lesson.htmlTypes));
p.setVar(info);

p.setLoop("list", list);
p.setVar("is_max", info.i("chapter") == maxChapter);
p.setVar("file_type", fileType);
p.setVar("otid", otid);
p.display();

%>