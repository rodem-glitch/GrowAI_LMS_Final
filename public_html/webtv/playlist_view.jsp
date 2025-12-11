<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
int categoryId = m.ri("cid");
String mode = m.rs("mode", "");
String ct = m.rs("ct", "lesson");
if(id == 0 || categoryId == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
WebtvDao webtv = new WebtvDao();
WebtvLogDao webtvLog = new WebtvLogDao(siteId);
WebtvTargetDao webtvTarget = new WebtvTargetDao();
WebtvPlaylistDao webtvPlaylist = new WebtvPlaylistDao();
LmCategoryDao category = new LmCategoryDao("webtv_playlist");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();

FileDao file = new FileDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

//정보
DataSet info = webtv.query(
	" SELECT a.*, p.category_id playlist_category_id, c.target_yn category_target_yn, c.login_yn, c.category_nm, l.id lesson_id, l.lesson_type, l.start_url, l.content_width, l.content_height "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + webtvPlaylist.table + " p ON a.id = p.webtv_id "
	+ " INNER JOIN " + category.table + " c ON p.category_id = c.id AND c.status = 1 "
	+ " LEFT JOIN " + lesson.table + " l ON " + ("audio".equals(ct) ? "a.audio_id" : "a.lesson_id") + " = l.id AND l.status = 1 "
	+ " WHERE a.id = " + m.ri("id") + " AND p.category_id = " + categoryId + " AND a.status = 1 AND a.display_yn = 'Y' AND a.site_id = " + siteId
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//권한검사
if(info.b("category_target_yn")) {
	if(1 > userId) { auth.loginForm(); return; }
	else if(1 > categoryTarget.findCount("category_id = " + info.i("playlist_category_id") + " AND group_id IN (" + userGroups + ")")) { m.jsError(_message.get("alert.common.permission_view")); return; }
}
if(info.b("login_yn") && 1 > userId) { auth.loginForm(); return; }

//포맷팅
info.put("audio_block", 0 < info.i("audio_id"));
info.put("audio_toggle", info.b("audio_block") && "audio".equals(ct) ? "lesson" : "audio");
info.put("image_url", m.getUploadUrl(info.s("webtv_file")));
info.put("open_date_conv", m.time(_message.get("format.datetime.dot"), info.s("open_date")));
info.put("open_day_conv", m.time(_message.get("format.date.dot"), info.s("open_date")));
info.put("open_day", m.time("yyyyMMdd", info.s("open_date")));
info.put("hit_cnt_conv", m.nf(info.i("hit_cnt")));
info.put("recomm_cnt_conv", m.nf(info.i("recomm_cnt")));
info.put("last_time", 0);
info.put("study_time", 0);
info.put("start_url_conv", "05".equals(info.s("lesson_type")) ? kollus.getPlayUrl(info.s("start_url"), "" + siteId + "_" + loginId, true, 0) : info.s("start_url"));
info.put("content_conv", m.stripTags(info.s("content")));
info.put("youtube_block", -1 < info.s("start_url").indexOf("youtube.com"));

if(!"".equals(info.s("webtv_file"))) {
	info.put("webtv_file_url", m.getUploadUrl(info.s("webtv_file")));
} else if("".equals(info.s("webtv_file_url"))) {
	info.put("webtv_file_url", "/common/images/default/noimage_webtv.jpg");
}

//변수
String today = m.time("yyyyMMdd");
int time = m.parseInt(m.time("HHmmss"));
boolean isOpen = 0 < m.diffDate("D", info.s("open_day"), today)	|| (0 == m.diffDate("D", info.s("open_day"), today) && time >= m.parseInt(m.time("HHmmss", info.s("open_date"))));

//제한
if("pop".equals(mode) && !isOpen) {
	m.jsErrClose(_message.get("alert.webtv.ready", new String[] {"open_date=>" + m.time(_message.get("format.datetime.dot"), info.s("open_date"))}));
	return;
}

//동영상경로보안
if("01".equals(info.s("lesson_type")) || "03".equals(info.s("lesson_type"))) {
	int lid = info.i("lesson_id");
    int unixTime = m.getUnixTime();
    String key = lid + "|" + userId + "|" + unixTime;
    String startUrl = "/main/video.jsp?ek=" + m.encrypt(key) + "&lid=" + lid + "&uid=" + userId + "&ut=" + unixTime;
    info.put("start_url", startUrl);
	info.put("start_url_conv", "/player/webtvplayer.jsp?lid=" + lid + "&ek=" + m.encrypt(lid + "|0|" + m.time("yyyyMMdd")));
}

//로그등록-읽기
if(0 < userId) webtvLog.log(userId, id);

//업데이트-조회수//쿠키셋팅
String[] readArray = m.getCookie("WTVREAD_" + info.i("playlist_category_id")).split("\\,");
if(!m.inArray("" + id, readArray)) {
	webtv.updateHitCount(id);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id : tmp + "," + id;
	m.setCookie("WTVREAD_" + info.i("playlist_category_id"), tmp, 3600 * 24);
}

//목록-파일
DataSet files = file.getFileList(id, "webtv");
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id") + m.time("yyyyMMdd")));
	files.put("sep", !files.b("__last") ? "<br>" : "");
}

//출력
if("pop".equals(mode)) {
	p.setLayout(null);
	p.setBody("course.preview_" + m.getItem(info.s("lesson_type"), lesson.htmlTypes));
} else {
	p.setLayout(ch);
	p.setBody("webtv.webtv_view");
}
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("ct_query", m.qs("ct"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setLoop("files", files);
p.setVar("open_block", isOpen);
p.setVar("file_block", files.size() > 0);
p.setVar("webtv_type", "playlist");
p.display();

%>