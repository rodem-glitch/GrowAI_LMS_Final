<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);
DoczoomDao doczoom = new DoczoomDao();

//목록
DataSet info = lesson.find("id = " + m.ri("id") + "");
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

info.put("last_time", 0);
info.put("study_time", 0);
info.put("start_url_conv", "05".equals(info.s("lesson_type")) ? kollus.getPlayUrl(info.s("start_url"), "" + siteId + "_" + loginId, true, 0) : info.s("start_url"));

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
	//kollus.d(out);
	String startUrl = kollus.getPlayUrl(info.s("start_url"), "" + siteId + "_sysop" + loginId);
	//String startUrl = "http://v.kr.kollus.com/s?key=" + kollus.getMediaToken(info.s("start_url"), "" + siteId + "_" + "sysop" + userId);

	if("https".equals(request.getScheme())) startUrl = startUrl.replace("http://", "https://");
	if("Y".equals(m.rs("download"))) {
		startUrl += "&download";
		p.setVar("download_block", true);
	}
	info.put("download_url", m.replace(startUrl, "//v.kr.kollus.com/s?", "//v.kr.kollus.com/si?"));
	info.put("start_url", startUrl);
	info.put("start_url_conv", startUrl);

	m.redirect(startUrl + "&uservalue0=" + (-1 * userId) + "&uservalue1=-99&uservalue2=-99&uservalue3=" + m.encrypt(siteId + sysToday + userId, "SHA-256"));
} else if("02".equals(info.s("lesson_type")) && m.isMobile()) {
	if(!"".equals(info.s("mobile_a")) && (info.s("mobile_a").endsWith(".mp4") || info.s("mobile_a").endsWith(".m3u8"))) {
		String startUrl = "/player/jwplayer.jsp?lid=" + lid + "&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd"));
		info.put("lesson_type", "03");
		info.put("start_url", startUrl);
		info.put("start_url_conv", startUrl);
	}
} else if("06".equals(info.s("lesson_type"))) {
	//컨텐츠 목록을 가져올 때 지정할 조건값들. Integer 변수에 null을 지정하면 해당 조건은 무시됩니다.
	String contentID = info.s("start_url");
	String userID = "malgn_" + siteinfo.s("ftp_id");
	//String startUrl = "https://cms.malgnlms.com/DocZoomManagementServer/DocZoomManager/ViewDocZoom.aspx?doczoomID=" + contentID;
	String startUrl = "https://cms.malgnlms.com/DocZoomMobile/doczoomviewer.asp?MediaID=" + contentID;

	DataSet dinfo = doczoom.getContentInfo(contentID);
	if(dinfo.next()) {
		String SessionID = doczoom.addContentViewerLoginSharedSessionData(userID, contentID, 10);
		if(SessionID != null) {
			startUrl += "&sessionID=" + SessionID;
			info.put("start_url", startUrl);
			info.put("start_url_conv", startUrl);
			info.put("lesson_type", "04");
		} else {
			m.jsErrClose("세션값을 가지오지 못했습니다."); return;
		}
	} else {
		m.jsErrClose("문서 정보를 조회할 수 없습니다."); return;
	}
} else if("04".equals(info.s("lesson_type"))) {
	if(info.s("start_url").contains("teams.microsoft.com") || info.s("start_url").contains("remotemeeting.com")) {
		m.redirect(info.s("start_url"));
		return;
	}
}

//출력
p.setLayout(null);
p.setBody("content.preview_" + m.getItem(info.s("lesson_type"), lesson.htmlTypes));
p.setVar(info);
p.setVar("file_type", fileType);
p.display();

%>