<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

if(!(Menu.accessible(926, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
WebtvLiveDao webtvLive = new WebtvLiveDao();
LessonDao lesson = new LessonDao();
MCal mcal = new MCal();

//정보
DataSet info = webtvLive.query(
	" SELECT a.*, l.lesson_nm, l.content_width, l.content_height "
	+ " FROM " + webtvLive.table + " a "
	+ " LEFT JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.site_id = " + siteId + " AND l.status != -1 "
	+ " WHERE a.site_id = " + siteId + " AND a.status != -1"
);
if(!info.next()) {
	webtvLive.item("site_id", siteId);
	webtvLive.item("start_date", m.time("yyyyMMddHH0000"));
	webtvLive.item("end_date", m.time("yyyyMMddHH0000"));
	webtvLive.item("login_yn", "N");
	webtvLive.item("status", "0");
	if(!webtvLive.insert()) { m.jsAlert("실시간방송 정보를 등록하는 중 오류가 발생했습니다."); return; }

	m.js("location.reload();");
	return;
}

f.addElement("live_nm", info.s("live_nm"), "hname:'라이브방송명', required:'Y'");
f.addElement("live_option", info.s("live_option"), "hname:'방송옵션값'");
f.addElement("option_desc", null, "hname:'방송옵션설명'");
f.addElement("lesson_id", info.i("lesson_id"), "hname:'방송강의', required:'Y'");
f.addElement("lesson_nm", info.s("lesson_nm"), "hname:'방송강의명'");
f.addElement("start_day", m.time("yyyy-MM-dd", info.s("start_date")), "hname:'방송시작일', required:'Y'");
f.addElement("start_time_hour", m.time("HH", info.s("start_date")), "hname:'방송시작시간', required:'Y'");
f.addElement("start_time_min", m.time("mm", info.s("start_date")), "hname:'방송시작시간(분)', required:'Y'");
f.addElement("end_day", m.time("yyyy-MM-dd", info.s("end_date")), "hname:'방송종료일', required:'Y'");
f.addElement("end_time_hour", m.time("HH", info.s("end_date")), "hname:'방송종료시간', required:'Y'");
f.addElement("end_time_min", m.time("mm", info.s("end_date")), "hname:'방송종료시간(분)', required:'Y'");
f.addElement("login_yn", info.s("login_yn"), "hname:'회원전용여부', required:'Y'");
f.addElement("status", info.s("status"), "hname:'상태', required:'Y'");

//수정
if(m.isPost() && f.validate()) {
	webtvLive.d(out);
	webtvLive.item("live_nm", f.get("live_nm"));
	webtvLive.item("live_option", f.get("live_option"));
	webtvLive.item("option_desc", f.get("option_desc"));
	webtvLive.item("lesson_id", f.getInt("lesson_id"));
	webtvLive.item("start_date", m.time("yyyyMMdd", f.get("start_day")) + f.get("start_time_hour") + f.get("start_time_min") + "00");
	webtvLive.item("end_date", m.time("yyyyMMdd", f.get("end_day")) + f.get("end_time_hour") + f.get("end_time_min") + "00");
	webtvLive.item("login_yn", f.get("login_yn"));
	webtvLive.item("status", f.get("status"));

	if(!webtvLive.update("site_id = " + siteId)) { m.jsAlert("라이브방송 정보를 수정하는 중 오류가 발생했습니다."); return; }
	m.jsAlert("라이브방송 정보가 수정되었습니다.");
	m.jsReplace("../webtv/webtv_live.jsp", "parent");
	return;
}

//포맷팅
info.put("option_desc_conv", m.nl2br(info.s("option_desc")));

//출력
p.setBody("webtv.webtv_live");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes(5));

p.setLoop("status_list", m.arr2loop(webtvLive.statusList));

p.display();

%>