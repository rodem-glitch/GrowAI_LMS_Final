<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//변수
String now = m.time("yyyyMMddHHmmss");

//객체
WebtvLiveDao webtvLive = new WebtvLiveDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

//목록
//webtvLive.d(out);
DataSet info = webtvLive.query(
	" SELECT a.live_nm, a.lesson_id, l.* "
	+ " FROM " + webtvLive.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.status != -1 "
	+ " WHERE a.site_id = " + siteId + " AND a.status != -1 "
	, 1
);
p.setVar("live_block", false);
if(info.next()) {
	info.put("start_url_conv", "05".equals(info.s("lesson_type")) ? ("http://v.kr.kollus.com/s?key=" + kollus.getMediaToken(info.s("start_url"), "" + userId)) : info.s("start_url"));

	//동영상경로보안
	if("01".equals(info.s("lesson_type")) || "03".equals(info.s("lesson_type"))) {
		int lid = info.i("lesson_id");
		int unixTime = m.getUnixTime();
		String key = lid + "|" + userId + "|" + unixTime;
		String startUrl = "/main/video.jsp?ek=" + m.encrypt(key) + "&lid=" + lid + "&uid=" + userId + "&ut=" + unixTime;
		info.put("start_url", startUrl);
		info.put("start_url_conv", "/player/webtvplayer.jsp?lid=" + lid + "&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd")));
	}

	p.setVar("live_block", true);
} else {
	return;
}

//출력
p.setLayout("blank");
p.setBody("webtv.webtv_live_preview");

p.setVar(info);
p.display();

%>