<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//기본키
int lid = m.ri("lid");
int uid = m.ri("uid");
String ek = m.rs("ek");
int ut = m.ri("ut");
String start = m.rs("start");

if(lid == 0 || ut == 0 || "".equals(ek)) {
	m.log("video", uid + "|no param");
	return;
}

//암호키
String key = lid + "|" + uid + "|" + ut;
if(!ek.equals(m.encrypt(key))) {
	m.log("video", key);
	return;
}

String referer = request.getHeader("referer");
String range = request.getHeader("range");
String agent = request.getHeader("User-Agent");

if(agent != null && agent.indexOf("Android") == -1 && agent.indexOf("Edge") == -1) {
	// 왜: 로컬 개발 환경에서는 referrer가 비어오는 브라우저가 있어, 동영상 로드가 막힐 수 있습니다.
	//     외부 노출은 그대로 막고, 로컬 접근만 예외로 허용합니다.
	boolean localAccess = userIp.startsWith("127.") || "0:0:0:0:0:0:0:1".equals(userIp) || "::1".equals(userIp);
	if((referer == null || "".equals(referer)) && !localAccess) {
		m.log("video", key + "|" + agent);
		return;
	}
}

//제한
int interval = 3600;
int now = m.getUnixTime();
//if(range == null && "".equals(start) && now - ut > interval) return;

//객체
LessonDao lesson = new LessonDao();

//목록
DataSet info = lesson.find("id = " + lid + " AND status != -1");
if(!info.next()) {  return; }

//모바일동영상
if(m.isMobile() && !"".equals(info.s("mobile_a")) && !info.s("start_url").equals(info.s("mobile_a"))) {
	info.put("start_url", info.s("mobile_a"));
}

m.log("video", info.s("start_url") + (!"".equals(start) ? ("&start=" + start) : ""));

m.redirect(info.s("start_url") + (!"".equals(start) ? ("&start=" + start) : ""));

%>
