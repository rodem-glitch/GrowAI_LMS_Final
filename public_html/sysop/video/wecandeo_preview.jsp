<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String accessKey = m.rs("access_key");
String packageId = m.rs("package_id");

int width = m.ri("v_width");
int height = m.ri("v_height");

if("".equals(accessKey) || "".equals(packageId)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

if(1 > width) width = 640;
if(1 > height) height = 360;

//객체
String videoKey = siteinfo.s("video_key");
WecandeoDao wecandeo = new WecandeoDao(videoKey);

String url = wecandeo.getPlayUrl(accessKey);
m.redirect(url);

%>