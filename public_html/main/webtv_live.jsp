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
	" SELECT a.live_nm, a.live_option, l.* "
	+ " FROM " + webtvLive.table + " a "
	+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.status != -1 "
	+ " WHERE a.site_id = " + siteId + " AND a.start_date <= '" + now + "' AND a.end_date >= '" + now + "' AND a.status = 1 "
	+ (1 > userId ? " AND a.login_yn = 'N' " : "")
	, 1
);
p.setVar("live_block", false);
if(info.next()) {
	info.put("start_url_conv", "05".equals(info.s("lesson_type")) ? kollus.getPlayUrl(info.s("start_url"), "" + siteId + "_" + loginId, true, 0) : info.s("start_url"));
	p.setVar("live_block", true);
}

//출력
p.setLayout(null);
p.setBody("main.webtv_live");

p.setVar(info);
p.display();

%>