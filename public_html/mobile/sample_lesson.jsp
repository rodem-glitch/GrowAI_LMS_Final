<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseDao course = new CourseDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

DataSet info = course.query(
	"SELECT b.* "
	+ " FROM " + course.table + " a "
	+ " INNER JOIN " + lesson.table + " b ON a.sample_lesson_id = b.id "
	+ " WHERE a.status = 1 AND a.id = " + m.ri("cid") + ""
);
if(!info.next()) { m.jsErrClose(_message.get("alert.course.nodata")); return; }

info.put("image_url", m.getUploadUrl(info.s("course_file")));
info.put("last_time", 0);
info.put("study_time", 0);
info.put("start_url_conv", "05".equals(info.s("lesson_type")) ? ("http://v.kr.kollus.com/s?key=" + kollus.getMediaToken(info.s("start_url"), "" + userId)) : info.s("start_url"));

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
	String startUrl = kollus.getPlayUrl(info.s("start_url"), "");
	if("https".equals(request.getScheme())) startUrl = startUrl.replace("http://", "https://");
	if("Y".equals(m.rs("download"))) startUrl += "&download";
	info.put("start_url", startUrl);
	info.put("start_url_conv", startUrl);
} else if("02".equals(info.s("lesson_type")) && m.isMobile()) {
	if(!"".equals(info.s("mobile_a")) && (info.s("mobile_a").endsWith(".mp4") || info.s("mobile_a").endsWith(".m3u8"))) {
		String startUrl = "/player/jwplayer.jsp?lid=" + lid + "&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd"));
		info.put("lesson_type", "03");
		info.put("start_url", startUrl);
		info.put("start_url_conv", startUrl);
	}
}

//출력
p.setLayout(null);
p.setBody("mobile.preview_" + m.getItem(info.s("lesson_type"), lesson.htmlTypes));
p.setVar(info);
p.setVar("file_type", fileType);
p.display();

%>