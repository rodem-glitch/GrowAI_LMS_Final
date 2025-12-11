<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseDao course = new CourseDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);
DoczoomDao doczoom = new DoczoomDao();

DataSet info = course.query(
	"SELECT b.*, a.course_file "
	+ " FROM " + course.table + " a "
	+ " INNER JOIN " + lesson.table + " b ON a.sample_lesson_id = b.id "
	+ " WHERE a.status = 1 AND a.id = " + m.ri("cid") + ""
);
if(!info.next()) { m.jsErrClose(_message.get("alert.course.nodata")); return; }

info.put("image_url", m.getUploadUrl(info.s("course_file")));
info.put("last_time", 0);
info.put("study_time", 0);
//info.put("start_url_conv", "05".equals(info.s("lesson_type")) ? ("http://v.kr.kollus.com/s?key=" + kollus.getMediaToken(info.s("start_url"), "")) : info.s("start_url"));

String fileType = "mp4";
int lid = info.i("id");

//동영상경로보안
if("01".equals(info.s("lesson_type")) || "03".equals(info.s("lesson_type"))) {
    int unixTime = m.getUnixTime();
    String key = lid + "|" + userId + "|" + unixTime;
    String startUrl = "/main/video.jsp?ek=" + m.encrypt(key) + "&lid=" + lid + "&uid=" + userId + "&ut=" + unixTime;
	if(info.s("start_url").endsWith(".m3u8")) fileType = "m3u8";
	else info.put("start_url", startUrl);
	info.put("start_url_conv", "/player/jwplayer.jsp?lid=" + lid + "&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd")));
} else if("05".equals(info.s("lesson_type"))) {
	//String startUrl = "http://v.kr.kollus.com/s?key=" + kollus.getMediaToken(info.s("start_url"), "");
	String startUrl = kollus.getPlayUrl(info.s("start_url"), "");
	if("https".equals(request.getScheme())) startUrl = startUrl.replace("http://", "https://");
	if("Y".equals(m.rs("download"))) {
		startUrl += "&download";
		p.setVar("download_block", true);
	}
	info.put("download_url", m.replace(startUrl, "//v.kr.kollus.com/s?", "//v.kr.kollus.com/si?"));
	info.put("start_url", startUrl);
	info.put("start_url_conv", startUrl);
} else if("02".equals(info.s("lesson_type")) && m.isMobile()) {
	if(!"".equals(info.s("mobile_a")) && (info.s("mobile_a").endsWith(".mp4") || info.s("mobile_a").endsWith(".m3u8"))) {
		String startUrl = "/player/jwplayer.jsp?lid=" + lid + "&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd"));
		info.put("lesson_type", "03");
		info.put("start_url", startUrl);
		info.put("start_url_conv", startUrl);
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

//출력
p.setLayout(null);
p.setBody("course.preview_" + m.getItem(info.s("lesson_type"), lesson.htmlTypes));
p.setVar(info);
p.setVar("file_type", fileType);
p.display();

%>