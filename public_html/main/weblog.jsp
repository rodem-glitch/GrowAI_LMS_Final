<%@ page contentType="text/html; charset=utf-8" %>
<%@ page import="java.net.*, java.util.regex.*, java.util.zip.CRC32" %>
<%@ include file="../init.jsp" %>
<%

if(!"".equals(userIp)) return;

// 제 3사 쿠키 차단 해제
response.setHeader("P3P",  "CP=\"NOI CURa ADMa DEVa TAIa OUR DELa BUS IND PHY ONL UNI COM NAV INT DEM PRE\""); 

String url = m.replace(f.get("url"), " ", "%20");
String ref = m.replace(f.get("ref"), " ", "%20");

//if("".equals(url)) return;

// 운영체제 테이블
String[] osList = {
    "windows nt 6.0=>WVI",
    "windows vista=>WVI",
    "windows nt 6.1=>WN7",
    "windows nt 5.2=>WS3",
    "windows server 2003=>WS3",
    "windows nt 5.1=>WXP",
    "windows xp=>WXP",
    "win98=>W98",
    "windows 98=>W98",
    "windows nt 5.0=>W2K",
    "windows 2000=>W2K",
    "windows nt 4.0=>WNT",
    "winnt=>WNT",
    "windows nt=>WNT",
    "win 9x 4.90=>WME",
    "windows me=>WME",
    "win32=>W95",
    "win95=>W95",
    "windows 95=>W95",
    "mac_powerpc=>MAC",
    "mac ppc=>MAC",
    "ppc=>MAC",
    "mac powerpc=>MAC",
    "mac os=>MAC",
    "linux=>LIN",
    "sunos=>SOS",
    "freebsd=>BSD",
    "aix=>AIX",
    "irix=>IRI",
    "hp-ux=>HPX",
    "os/2=>OS2",
    "netbsd=>NBS",
    "unknown=>UNK"
};

String[] brList = {
    "msie=>IE",
    "firefox=>FF",
    "chrome=>CR",
    "safari=>SF",
    "opera=>OP",
    "netscape=>NS",
    "galeon=>GA",
    "phoenix=>PX",
    "firebird=>FB",
    "seamonkey=>SM",
    "chimera=>CH",
    "camino=>CA",
    "k-meleon=>KM",
    "mozilla=>MO",
    "konqueror=>KO",
    "icab=>IC",
    "lynx=>LX",
    "links=>LI",
    "ncsa mosaic=>MC",
    "amaya=>AM",
    "omniweb=>OW",
    "hotjava=>HJ",
    "browsex=>BX",
    "amigavoyager=>AV",
    "amiga-aweb=>AW",
    "ibrowse=>IB",
    "unknown=>UN"
};

// 클라이언트 정보를 가져온다.
String agent = request.getHeader("user-agent").toLowerCase();

// 운영체제 정보를 얻는다.
String os = "UNK";
for(int i=0; i<osList.length; i++) {
	String[] tmp = osList[i].split("=>");
	if(agent.indexOf(tmp[0]) > -1) {
		os = tmp[1];
		break;
	}
}

// 브라우저 정보를 얻는다.
Pattern pattern = Pattern.compile("([\\.0-9]+)");
String brower = "UN";
String brVersion = "";
for(int i=0; i<brList.length; i++) {
	String[] tmp = brList[i].split("=>");
	int pos = agent.indexOf(tmp[0]);
	if(pos > -1) {
		brower = tmp[1];
		Matcher matcher = pattern.matcher(agent.substring(pos));
		if(matcher.find()) {
			brVersion = agent.substring(pos).substring(matcher.start(), matcher.end());
		} 
		break;
	}
}

// USERAGENT 정보를 올바르지 않을 경우 거부한다.
if(os == "UNK" && brower == "UN") return;

// 오늘 하루 첫 방문 여부
int first_visit = 1;

// 재방문 카운트
int visit_count = 1;

// 오늘 재방문 여부
int return_visit = 0;

// 방문자 고유 아이디
String access_id = m.md5(userIp + agent + m.getTimeString());
String visitor_id = access_id;

// 접속 페이지 아이디
String host = "";
String page_id = "";
if(!"".equals(url)) {
	URL purl = new URL(url);
	host = purl.getHost();
	String path = purl.getPath();
	String query = purl.getQuery();
	if(query != null) path = path + "?" + query;
	page_id = m.md5(path);
}

String ref_host = "";
String referer_id = "";
if(!"".equals(ref)) {
	URL pref = new URL(ref);
	ref_host = pref.getHost();
	if(!host.equals(ref_host)) {
		referer_id = m.md5(ref);
	}
}

String last_page_id = "";

// 쿠키가 존재할 경우
String cid = "WEBLOGID";
String secret_key = "weblog_200811112";
String cookie = m.getCookie(cid);
long currentTime = System.currentTimeMillis() / 1000;

if(!"".equals(cookie)) {
	cookie = Base64Coder.decode(cookie);
	String[] arr = cookie.split("\\|");

	// 쿠키의 정보 갯수가 맞는지와 고객 아이디가 일치하는지 확인
	if(arr.length == 5) {
		long delay_time = currentTime - m.parseLong(arr[0]);
		visitor_id = arr[1];

		// 쿠키가 1시간 이전 정보일 경우 재접속으로 간주한다.
		if(delay_time < 3600) {
			return;
		} else {
			visit_count = m.parseInt(arr[4]) + 1;
		}
	}
}

// 브라우저에 방문 정보 쿠키를 굽는다.
String cookie_id = Base64Coder.encode(currentTime + "|" + visitor_id + "|" + access_id + "|" + page_id + "|" + visit_count);
m.setCookie(cid, cookie_id, (int)(currentTime + (365 * 24 * 3600 * 10)));

// 로그 포맷(순서)를 지정한다.
DataObject weblog = new DataObject("TB_WEBLOG");
weblog.item("log_date", m.getTimeString("yyyyMMdd"));
weblog.item("access_id", access_id);
weblog.item("visitor_id", visitor_id);
weblog.item("host_ip", userIp);
weblog.item("os", os);
weblog.item("browser", brower + " " + brVersion);
weblog.item("timezone", m.reqInt("tz"));
weblog.item("resolution", f.get("res"));
weblog.item("lang", f.get("lang").toUpperCase());
weblog.item("weekday", m.getTimeString("W"));
weblog.item("hour", m.getTimeString("HH"));
weblog.item("day", m.getTimeString("dd"));
weblog.item("month", m.getTimeString("MM"));
weblog.item("year", m.getTimeString("yyyy"));
weblog.item("log_time", currentTime);
weblog.item("visit_count", visit_count);
weblog.item("referer_id", referer_id);


//weblog.setDebug(out);
if(!weblog.insert()) {
	m.log("weblog", weblog.errMsg);	
}

/*
if(!"".equals(referer_id)) {
	WeblogRefererDao referer = new WeblogRefererDao();
	referer.item("id", referer_id);
	referer.item("domain", ref_host);
	referer.item("referer", ref);
	if(!referer.insert()) {
		m.log("weblog", referer.errMsg);	
	}
}
*/

%>