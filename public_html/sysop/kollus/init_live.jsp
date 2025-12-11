<%@ include file="../init.jsp" %><%@ page import="java.net.URL,javax.net.ssl.*,java.time.*,java.text.SimpleDateFormat" %><%@ page import="malgnsoft.json.*" %><%@ page import="java.util.HashMap" %><%

String ch = "sysop";

//객체
KollusDao kollus = new KollusDao(siteId);
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();

//검사
if("".equals(SiteConfig.s("kollus_live_access_token"))) {
    //기본키
    String code = m.rs("code");
    String state = m.rs("state");

    String clientId = SiteConfig.s("kollus_live_oauth_id");
    String clientSecret = SiteConfig.s("kollus_live_oauth_secret");
    String returnUri = "https://lms.malgn.co.kr/sysop/kollus/live_list.jsp";

    //객체
    OAuthClient oauth = new OAuthClient(request, session);
    //out.println("<style>body {word-break: break-all;}</style>");
    //oauth.setDebug(out);
    oauth.setClient("kollus_live", clientId, clientSecret, (!"Y".equals(siteinfo.s("ssl_yn")) ? "http" : "https") + "://" + siteinfo.s("domain") + "/sysop/kollus/live_list.jsp");

    //처리-승인
    if("".equals(code) || "".equals(state)) {
        m.jsAlert("콜러스 라이브 사용 시 최초 1회에 한하여 권한승인이 필요합니다.\\n콜러스 계정으로 로그인 후 \'Authorize\'를 눌러주세요.");
        //m.redirect(oauth.getAuthUrl("kollus_live"));
        m.js("window.open('" + oauth.getAuthUrl("kollus_live") + "', '_KLIVE_ACCESS_');");
        return;
    }

    //처리-토큰
    String token = oauth.getAccessToken(code);
    if("".equals(token)) { m.redirect(oauth.getAuthUrl("kollus_live")); return; }

    //저장-토큰
    SiteConfig.put("kollus_live_access_token", token);
    SiteConfig.remove(siteId + "");

    m.js("location.href = location.href;");
    return;

}

%>