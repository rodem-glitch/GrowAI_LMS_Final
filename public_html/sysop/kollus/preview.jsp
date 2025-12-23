<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String key = m.rs("key");
if("".equals(key)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
KollusDao kollus = new KollusDao(siteId);
String url = kollus.getPlayUrl(key, "" + siteId + "_sysop" + loginId);

// 왜: 기존 파일이 디버깅 중 `System.out.println`만 남고 실제 출력/이동이 없어 "흰 화면"이 발생했습니다.
//     sysop의 동영상 관리 화면에서 "미리보기"를 눌렀을 때, 콜러스 재생 URL로 즉시 이동시켜야 합니다.
if("https".equals(request.getScheme())) url = url.replace("http://", "https://");

m.redirect(url + "&uservalue0=" + (-1 * userId) + "&uservalue1=-99&uservalue2=-99&uservalue3=" + m.encrypt(siteId + sysToday + userId, "SHA-256"));

%>
