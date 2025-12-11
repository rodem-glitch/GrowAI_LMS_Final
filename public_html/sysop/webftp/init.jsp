<%@ include file="../init.jsp" %><%@ page import="org.apache.commons.net.ftp.*" %>
<%

//접근권한
if(!Menu.accessible(47, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

String ch = "sysop";
String ftpHost = "localhost";
String ftpId = siteinfo.s("ftp_id");
String ftpPw = siteinfo.s("ftp_pw");
int ftpPort = 21;

/*if(isDevServer) {
    //ftpId = "intern";
    //ftpPw = "OHrXQqC0Y7";
}*/

%><%!
public int loginValidate(FTPClient ftp, Malgn m, String ftpId, String ftpPw) throws Exception {
    String cookName = "OFNISSECCAPTFBEW";
    String cookie = m.getCookie(cookName);
    String currentTime = m.time("yyyyMMddHHmmss");
    String prevTime = "";
    int loginFailCount = 0;

    if (!"".equals(cookie)) {
        cookie = Base64Coder.decode(cookie);
        String[] arr = cookie.split("\\|");
        loginFailCount = m.parseInt(arr[0]);
        prevTime = (arr.length == 2 ? (!"".equals(arr[1]) ? arr[1] : "") : "");


        // 현재시간이 이전시간보다 5분 이상 이면 로그인 실패 횟수와 시간을 초기화 해준다.
        if (!"".equals(prevTime) && 5 <= m.diffDate("I", prevTime, currentTime)) {
            loginFailCount = 0;
            prevTime = "";
        }
    }

    //실패횟수가 5회보다 많으면 로그인 실패 횟수와 시간이 초기화되기 전까지 로그인을 제한한다.
    if (5 <= loginFailCount) { return -1; }

    //로그인 실패 검사
    if (!ftp.login(ftpId, ftpPw)) {
        loginFailCount++;

        // 브라우저에 방문 정보 쿠키를 굽는다.
        String cookieValue = Base64Coder.encode(loginFailCount + "|" + (5 <= loginFailCount && "".equals(prevTime) ? currentTime : prevTime));
        m.setCookie(cookName, cookieValue);

        return -2;

    } else {
        m.delCookie(cookName);
    }

    return 1;
}
%>