<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
String mode = m.rs("mode", "");
String ct = m.rs("ct", "lesson");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
WebtvDao webtv = new WebtvDao();
WebtvLogDao webtvLog = new WebtvLogDao(siteId);
WebtvTargetDao webtvTarget = new WebtvTargetDao();
LmCategoryDao category = new LmCategoryDao("webtv");
LmCategoryTargetDao categoryTarget = new LmCategoryTargetDao();

FileDao file = new FileDao();
LessonDao lesson = new LessonDao();
KollusDao kollus = new KollusDao(siteId);

//정보
DataSet info = webtv.query(
	" SELECT a.*, c.category_nm, c.target_yn category_target_yn, c.login_yn, c.hit_cycle, l.id lesson_id, l.lesson_type, l.start_url, l.content_width, l.content_height "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	+ " LEFT JOIN " + lesson.table + " l ON " + ("audio".equals(ct) ? "a.audio_id" : "a.lesson_id") + " = l.id AND l.status = 1 "
	+ " WHERE a.id = " + m.ri("id") + " AND a.status = 1 AND a.display_yn = 'Y' AND a.site_id = " + siteId + " AND (a.end_yn = 'N' OR a.end_yn = 'Y' AND a.end_date >= '" + m.time("yyyyMMddHHmmss") + "') "
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//권한검사
if(info.b("target_yn")) {
	if(1 > userId) { auth.loginForm(); return; }
	else if(1 > webtvTarget.findCount("webtv_id = " + info.i("id") + " AND group_id IN (" + (!"".equals(userGroups) ? userGroups : "0") + ")")) { m.jsError(_message.get("alert.common.permission_view")); return; }
}
if(info.b("category_target_yn")) {
	if(1 > userId) { auth.loginForm(); return; }
	else if(1 > categoryTarget.findCount("category_id = " + info.i("category_id") + " AND group_id IN (" + (!"".equals(userGroups) ? userGroups : "0") + ")")) { m.jsError(_message.get("alert.common.permission_view")); return; }
}
if(info.b("login_yn") && 1 > userId) { auth.loginForm(); return; }

//포맷팅
info.put("audio_block", 0 < info.i("audio_id"));
info.put("audio_toggle", info.b("audio_block") && "audio".equals(ct) ? "lesson" : "audio");
info.put("subtitle_conv", m.nl2br(info.s("subtitle")));
info.put("subtitle_conv2", m.nl2br(m.stripTags(info.s("subtitle"))));
info.put("image_url", m.getUploadUrl(info.s("webtv_file")));
info.put("open_date_conv", m.time(_message.get("format.datetime.dot"), info.s("open_date")));
info.put("open_day_conv", m.time(_message.get("format.date.dot"), info.s("open_date")));
info.put("open_day", m.time("yyyyMMdd", info.s("open_date")));
info.put("hit_cnt_conv", m.nf(info.i("hit_cnt")));
info.put("recomm_cnt_conv", m.nf(info.i("recomm_cnt")));
info.put("last_time", 0);
info.put("study_time", 0);
if("04".equals(info.s("lesson_type"))) {
	info.put("start_url_conv", info.s("start_url"));
	info.put("link_block", true);

} else if("05".equals(info.s("lesson_type"))) {
	String startUrl = kollus.getPlayUrl(info.s("start_url"), "" + siteId + "_" + loginId, true, 0);
	if("https".equals(request.getScheme())) startUrl = startUrl.replace("http://", "https://");
	info.put("start_url", startUrl);
	info.put("start_url_conv", startUrl);

} else if("07".equals(info.s("lesson_type"))) {
	String startUrl = kollus.getLiveUrl(info.s("start_url"), "" + siteId + "_" + loginId) + "&custom_key=" + SiteConfig.s("kollus_live_custom_key");
	if("https".equals(request.getScheme())) startUrl = startUrl.replace("http://", "https://");
	info.put("start_url", startUrl);
	info.put("start_url_conv", startUrl);

} else {
	info.put("start_url_conv", info.s("start_url"));
}
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
if(isOpen && 0 < userId) webtvLog.log(userId, id, info.i("hit_cycle"));

//업데이트-조회수//쿠키셋팅
String[] readArray = null;
readArray = m.getCookie("WEBTV_VIEW_" + info.i("category_id")).split("\\,");
if(!m.inArray("" + id, readArray)) {
	webtv.updateHitCount(id);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id : tmp + "," + id;
	m.setCookie("WEBTV_VIEW_" + info.i("category_id"), tmp, 3600 * info.i("hit_cycle"));
}

//키워드
String keywords[] = new String[] {};
if(!"".equals(info.s("keywords"))) keywords = m.split("|", info.s("keywords"));

//목록-파일
DataSet files = file.getFileList(id, "webtv");
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id") + m.time("yyyyMMdd")));
	files.put("sep", !files.b("__last") ? "<br>" : "");
}

//목록-연관콘텐츠
DataSet rlist = webtv.query(
	" SELECT a.*, c.parent_id "
	+ " FROM " + webtv.table + " a "
	+ " INNER JOIN " + category.table + " c ON a.category_id = c.id AND c.status = 1 "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 1 AND a.display_yn = 'Y' "
	+ " AND a.id != " + id + " "
	+ " AND a.category_id IN (" + category.getSubIdx(siteId, info.i("category_id")) + ") "
	+ " AND a.open_date <= '" + m.time("yyyyMMddHHmmss") + "' "
	+ " AND (a.target_yn = 'N' " //시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + webtvTarget.table + " WHERE webtv_id = a.id AND group_id IN (" + userGroups + ")) "
		: "")
	+ " ) "
	+ " AND (c.target_yn = 'N' " //카테고리시청대상그룹
	+ (!"".equals(userGroups)
		? " OR EXISTS (SELECT 1 FROM " + categoryTarget.table + " WHERE category_id = c.id AND group_id IN (" + userGroups + ")) "
		: "")
	+ " ) "
	+ (1 > userId ? " AND c.login_yn = 'N' " : "")
	+ " ORDER BY a.id * RAND() DESC "
	, 10
);
while(rlist.next()) {
	rlist.put("webtv_nm_conv", m.cutString(rlist.s("webtv_nm"), 70));
	
	rlist.put("subtitle_conv", m.nl2br(rlist.s("subtitle")));
	rlist.put("length_conv", m.strpad(rlist.s("length_min"), 2, "0") + ":" + m.strpad(rlist.s("length_sec"), 2, "0"));

	if(!"".equals(rlist.s("webtv_file"))) {
		rlist.put("webtv_file_url", m.getUploadUrl(rlist.s("webtv_file")));
	} else if("".equals(rlist.s("webtv_file_url"))) {
		rlist.put("webtv_file_url", "/common/images/default/noimage_webtv.jpg");
	}

	rlist.put("open_date_conv", m.time(_message.get("format.datetime.dot"), rlist.s("open_date")));
	rlist.put("open_day_conv", m.time(_message.get("format.date.dot"), rlist.s("open_date")));
}

//목록-카테고리
category.setData(category.getList(siteId));
DataSet parents = category.getParentList(siteId, info.i("category_id"));

//출력
if("pop".equals(mode)) {
	p.setLayout(null);
	p.setBody("course.preview_" + m.getItem(info.s("lesson_type"), lesson.htmlTypes));
} else {
	p.setLayout(ch);
	p.setBody("webtv.webtv_view");
}
p.setVar("p_title", info.s("category_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("mode_query", m.qs("mode"));
p.setVar("ct_query", m.qs("ct"));
p.setVar("search_query", m.qs("id,s_field,s_keyword"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setLoop("parents", parents);
p.setLoop("related_list", rlist);
p.setLoop("files", files);
p.setLoop("keywords", m.arr2loop(keywords));
p.setVar("open_block", isOpen);
p.setVar("file_block", files.size() > 0);
p.setVar("webtv_type", "webtv");

p.setVar("grade_title", Malgn.getItem(info.s("grade"), webtv.grades));
p.setVar("term_title", Malgn.getItem(info.s("term"), webtv.terms));
p.setVar("subject_title", Malgn.getItem(info.s("subject"), webtv.subjects));

p.display();

%>