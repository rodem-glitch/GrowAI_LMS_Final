<%@ page contentType="text/html; charset=utf-8" %><%@ page import="malgnsoft.json.*" %>
<%@ include file="init.jsp" %><%

//기본키
String clientUserId = m.rs("user_id", m.rs("client_user_id")); // 정상적인 진도시 : COURSE_USER.id + _ + COURSE_MODULE.module_id // 맛보기 : 12자리랜덤값
int cuid = m.ri("uval0", m.ri("uservalue0")); // COURSE_USER.id
int lid = m.ri("uval1", m.ri("uservalue1")); // COURSE_LESSON.lesson_id
int chapter = m.ri("uval2", m.ri("uservalue2")); // COURSE_LESSON.chapter
int studyTime = m.ri("play_time");
int playTime = m.ri("play_time");
int normalPlayTime = m.ri("play_time"); //구간반복 포함
int showTime = 0; //구간반복 포함
int currTime = m.ri("last_play_at");
String startTime = m.rs("start_at");
String jsonData = m.rs("json_data");

//객체
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
CourseUserDao courseUser = new CourseUserDao();
KollusLogDao kollusLog = new KollusLogDao();

//변수
boolean isLog = true;
StringBuffer em = new StringBuffer();

if(isLog) {
	em.append("START LOG - " + m.getUnixTime() + " -- " + m.time("yyyy.MM.dd HH:mm:ss") + "\r\n\r\n");
	if(m.parseInt(m.time("HHmm")) > 2200 ) em.append("I really want to go home!!, my lord\r\n\r\n");
	StringBuffer sb = new StringBuffer();
	Enumeration params = request.getParameterNames();
	while(params.hasMoreElements()) {
		String key = (String)params.nextElement();
		for(int i=0; i<request.getParameterValues(key).length; i++) {
			if(!"json_data".equals(key)) sb.append("[" + key + "] => " + request.getParameterValues(key)[i] + " | ");
		}
	}
	em.append("KOLLUS_PROGRESS_VERSION - " + SiteConfig.s("kollus_progress_version") + "\r\n");
	em.append("PARAMS - " + sb.toString() + "\r\n\r\n");
	em.append("client_user_id = " + clientUserId + " | cuid - " + cuid + " | lesson_id - " + lid + " | chapter - " + chapter +  "\r\n");
	em.append("start_at - " + startTime + " | form.play_time - " + playTime + " | last_play_at - " + currTime + "\r\n");
}

//변수
JSONObject jo = new JSONObject();
JSONObject co = new JSONObject();
boolean jsonBlock = false;
String playerId = "";

if(!"".equals(jsonData)) {
	try {
		jo = new JSONObject(jsonData);
		co = jo.getJSONObject("content_info");

		playTime = co.getInt("real_playtime");
		studyTime = co.getInt("playtime");
		normalPlayTime = co.getInt("playtime");

		showTime = !co.isNull("showtime") ? co.getInt("showtime") : -1;
		startTime = co.getString("start_at");
		currTime = co.getInt("last_play_at");
//		clientUserId = jo.getJSONObject("user_info").getString("client_user_id");

		clientUserId = !jo.getJSONObject("user_info").isNull("client_user_id") ? jo.getJSONObject("user_info").getString("client_user_id") : "0";

		playerId = jo.getJSONObject("user_info").getString("player_id");
		//cuid = m.parseInt(jo.getJSONObject("uservalues").getString("uservalue0"));
		//lid = m.parseInt(jo.getJSONObject("uservalues").getString("uservalue1"));
		//chapter = m.parseInt(jo.getJSONObject("uservalues").getString("uservalue2"));
		jsonBlock = true;

	} catch(JSONException jsone) {
		m.errorLog("site_id : " + siteId + "JSONException : " + jsone.getMessage() + "jo : " + jo.toString(), jsone);
		m.log("kollus_json",  "site_id : " + siteId + " / Json : " + jsonData + " / Error : " + jsone.getMessage());
		return;
	} catch(Exception e) {
		m.errorLog("site_id : " + siteId + "Exception : " + e.getMessage() + "jo : " + jo.toString(), e);
		m.log("kollus_json", "site_id : " + siteId + " / Json : " + jsonData + " / Error : " + e.getMessage());
		return;
	}

}

if(clientUserId.indexOf("_") == -1 || cuid == 0) {
	 m.log("kollus", "ERROR : userId=" + clientUserId + ", cuid=" + cuid + ", lid=" + lid + ", add_study_time=" + studyTime + ", last_play_at=" + currTime);
	if(isLog) {
		em.append("\r\nEND LOG - " + m.getUnixTime() + " -- " + m.time("yyyy.MM.dd HH:mm:ss") + "\r\n\r\n");
		m.log("kollus_log", em.toString());
	}
	return;
}

DataSet cpinfo = courseProgress.find("course_user_id = ? AND lesson_id = ?", new Object[] {cuid, lid});
if(!cpinfo.next()) { }
cpinfo.put("start_at",  !"".equals(cpinfo.s("paragraph")) ? m.split("-", cpinfo.s("paragraph"), 2)[0] : "0");
cpinfo.put("prev_playtime",  !"".equals(cpinfo.s("paragraph")) ? m.split("-", cpinfo.s("paragraph"), 2)[1] : "0");

//제한
if(lid == 0 || currTime == 0) {
	m.log("kollus"
		, "NOT ENOUGH DATA - lid or last_play_at \r\nuserId=" + clientUserId + ", cuid=" + cuid + ", lid=" + lid + ", add_study_time=" + studyTime + ", last_play_at=" + currTime + ", cp.study_time=" + cpinfo.s("study_time") + ", cp.start_at=" + cpinfo.s("start_at") + ", cp.prev_playtime=" + cpinfo.s("prev_playtime") + ", play_time=" + playTime + ", normal_play_time=" + normalPlayTime + ", showtime=" + showTime
	);
	if(isLog) {
		em.append("\r\nEND LOG - " + m.getUnixTime() + " -- " + m.time("yyyy.MM.dd HH:mm:ss") + "\r\n\r\n");
		m.log("kollus_log", em.toString());
	}
	return;
}


//처리
if(m.parseLong(startTime) == cpinfo.l("start_at")) { //세션 유지(폼값 == 저장된값) -- 갱신
	 studyTime -= cpinfo.i("prev_playtime");
    if(studyTime < 0) studyTime = 0;
} else  if(m.parseLong(startTime) < cpinfo.l("start_at")) { //세션 무시-순서 잘못됬거나 역순 데이터인 경우
	m.log("kollus"
		, "IGNORE DATA - start_at < cp.start_at \r\nuserId=" + clientUserId + ", cuid=" + cuid + ", lid=" + lid + ", add_study_time=" + studyTime + ", last_play_at=" + currTime + ", cp.study_time=" + cpinfo.s("study_time") + ", cp.start_at=" + cpinfo.s("start_at") + ", cp.prev_playtime=" + cpinfo.s("prev_playtime") + ", play_time=" + playTime + ", normal_play_time=" + normalPlayTime + ", showtime=" + showTime + ", start_at=" + startTime
	);
	if(isLog) {
		em.append("\r\nEND LOG - " + m.getUnixTime() + " -- " + m.time("yyyy.MM.dd HH:mm:ss") + "\r\n\r\n");
		m.log("kollus_log", em.toString());
	}
	return;
} if(m.parseLong(startTime) > cpinfo.l("start_at")) {  //세션 초기화
	//studyTime = 30;
}

//등록수정-콜러스로그
if(jsonBlock && "2".equals(SiteConfig.s("kollus_progress_version"))) {

	//kollusLog.d(out);
	kollusLog.item("serial", co.getInt("serial"));
	kollusLog.item("last_play_at", co.getInt("last_play_at"));
	kollusLog.item("real_playtime", studyTime);
	kollusLog.item("playtime", co.getInt("playtime"));
	kollusLog.item("runtime", co.getInt("runtime"));
	kollusLog.item("showtime", !co.isNull("showtime") ? co.getInt("showtime") : -1);

	if(1 > kollusLog.findCount("course_user_id = ? AND lesson_id = ? AND start_at = ?", new Object[] {cuid, lid, co.getInt("start_at")})) {
		kollusLog.item("site_id", siteId);
		kollusLog.item("course_user_id", cuid);
		kollusLog.item("user_id", cpinfo.i("user_id"));
		kollusLog.item("course_id", cpinfo.i("course_id"));
		kollusLog.item("chapter", chapter);
		kollusLog.item("lesson_id", lid);
		kollusLog.item("before_study_time", cpinfo.i("study_time"));
		kollusLog.item("start_at", co.getLong("start_at"));
		kollusLog.item("user_ip_addr", userIp);
		kollusLog.item("player_id", playerId);
		kollusLog.item("reg_date", sysNow);
		kollusLog.item("status", 1);

		kollusLog.insert();
	} else {
		kollusLog.update("course_user_id = " + cuid + " AND lesson_id = " + lid + " AND start_at = " + co.getInt("start_at"));
	}

	//courseProgress.setTotalPlayTime(kollusLog.getOneInt("SELECT SUM(playtime) FROM " + kollusLog.table + " WHERE course_user_id = " + cuid + " AND lesson_id = " + lid));
	courseProgress.setTotalPlayTime(kollusLog.getOneInt("SELECT before_study_time + playtime FROM " + kollusLog.table + " WHERE course_user_id = " + cuid + " AND lesson_id = " + lid + " AND start_at = " + co.getInt("start_at")));
	courseProgress.setStudyTime(0);
	courseProgress.setCurrTime(currTime);

} else {
	courseProgress.setTotalPlayTime(0);
	courseProgress.setStudyTime(studyTime);
	courseProgress.setCurrTime(currTime);
}
courseProgress.item("paragraph", startTime + "-" + normalPlayTime);
int ret = courseProgress.updateProgress(cuid, lid, chapter);

m.log("kollus"
	, "SUCCESS :: userId=" + clientUserId + ", cuid=" + cuid + ", lid=" + lid + ", add_study_time=" + studyTime + ", last_play_at=" + currTime + ", cp.study_time=" + cpinfo.s("study_time") + ", cp.start_at=" + cpinfo.s("start_at") + ", cp.prev_playtime=" + cpinfo.s("prev_playtime") + ", play_time=" + playTime + ", normal_play_time=" + normalPlayTime + ", showtime=" + showTime + ", start_at=" + startTime + ", ret=" + ret
);

//수강생 정보 업데이트
if(ret == 2) {
	courseUser.setProgressRatio(cuid);
	courseUser.updateScore(cuid, "progress"); //점수일괄업데이트
	courseUser.closeUser(cuid, userId);
}

if(isLog) {
	em.append("add_study_time - " + studyTime + " | last_play_at - " + currTime + " | cp.study_time - " + cpinfo.s("study_time") + "\r\n");
	em.append("cp.start_at - " + cpinfo.s("start_at") + " | cp.prev_playtime - " + cpinfo.s("prev_playtime") + " | play_time - " + playTime + " | normal_play_time - " + normalPlayTime + "\r\n");
	em.append("showtime - " + showTime + " | start_at - " + startTime + "\r\n");
	em.append("\r\nEND LOG - " + m.getUnixTime() + " -- " + m.time("yyyy.MM.dd HH:mm:ss") + "\r\n\r\n");
	m.log("kollus_log", em.toString());
}

%>