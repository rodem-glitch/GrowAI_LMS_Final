<%@ page contentType="text/html; charset=utf-8" %><%@ page import="eu.bitwalker.useragentutils.*" %><%@ include file="/init.jsp" %><%

//기본키
int lid = m.ri("lid");
int cuid = m.ri("cuid");
int chapter = m.ri("chapter");
int nid = m.ri("nid");
int start = m.ri("start");
int vid = m.ri("vid"); //다중영상일 때 서브영상 id
int plid = m.ri("plid"); //다중영상일 때 부모 차시 id(진도 저장용)
if(plid == 0) plid = lid;
String ek = m.rs("ek");

if(lid == 0) { m.jsErrClose(_message.get("alert.common.required_key")); return; }
if(cuid > 0 && userId == 0) { m.jsErrClose(_message.get("alert.member.required_login")); return; }
if(!ek.equals(m.encrypt(lid + "|" + cuid + "|" + m.time("yyyyMMdd")))) { m.jsErrClose(_message.get("alert.common.abnormal_access")); return; }

//객체
LessonDao lesson = new LessonDao();
CourseProgressDao courseProgress = new CourseProgressDao();
CourseProgressVideoDao courseProgressVideo = new CourseProgressVideoDao();

//목록
// 다중 영상 차시(vid > 0)에서는 진도 테이블이 LM_COURSE_PROGRESS_VIDEO 이므로,
// 부모차시(plid) + 영상(vid) 기준으로 이어보기/완료여부를 조회해야 정상 동작합니다.
String progressFields = "";
String progressJoin = "";
if(cuid > 0) {
	progressFields = ", p.last_time, p.curr_time, p.complete_yn ";
	progressJoin = (vid > 0)
		? " LEFT JOIN " + courseProgressVideo.table + " p ON p.course_user_id = " + cuid + " AND p.lesson_id = " + plid + " AND p.video_id = " + vid + " AND p.status = 1 "
		: " LEFT JOIN " + courseProgress.table + " p ON p.course_user_id = " + cuid + " AND p.lesson_id = a.id ";
}

DataSet info = lesson.query(
	"SELECT a.* " + (cuid > 0 ? progressFields : "")
	+ " FROM " + lesson.table + " a "
	+ (cuid > 0 ? progressJoin : "")
	+ " WHERE a.status = 1 AND a.id = " + lid
);
if(!info.next()) { m.jsErrClose(_message.get("alert.lesson.nodata")); return; }

info.put("lesson_nm_conv", m.cutString(info.s("lesson_nm"), 40));
info.put("total_time", info.i("total_time") * 60);

//모바일동영상
if(m.isMobile() && !"".equals(info.s("mobile_a")) && !info.s("start_url").equals(info.s("mobile_a"))) {
	info.put("start_url", info.s("mobile_a"));
}

String fileType = "mp4";

int unixTime = m.getUnixTime();
String key = lid + "|" + userId + "|" + unixTime;
String startUrl = "/main/video.jsp?ek=" + m.encrypt(key) + "&lid=" + lid + "&uid=" + userId + "&ut=" + unixTime;
info.put("start_url_original", info.s("start_url"));
if(info.s("start_url").endsWith(".m3u8")) {
	info.put("start_url_conv", info.s("start_url"));
	fileType = "m3u8";
} else if(info.s("start_url").endsWith(".m4a")) {
	info.put("start_url_conv", startUrl);
	fileType = "m4a";
} else {
	info.put("start_url_conv", startUrl);
}

boolean ie8 = false;
UserAgent ua = new UserAgent(request.getHeader("User-Agent"));
String browser = ua.getBrowser().getName();
Version version = ua.getBrowserVersion();
String major = null != version ? version.getMajorVersion() : "11";
if(browser.indexOf("Explorer") > 0) {
	int ver = m.parseInt(null != major ? major : "11");
	if(ver <= 8) ie8 = true;
}

//출력
p.setLayout(null);
p.setBody("player.webtvplayer");
p.setVar(info);
p.setVar("file_type", fileType);
p.setVar("last_time", info.i("last_time"));
p.setVar("start_pos", start > 0 ? start : info.i("curr_time"));
p.setVar("progress_block", cuid > 0);
p.setVar("complete_block", "Y".equals(info.s("complete_yn")));
p.setVar("next_lesson_id", nid > 0);
p.setVar("ie8", ie8);
p.setVar("vid", vid);
p.setVar("plid", plid);
p.display();

%>
