<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.json.*" %><%@ include file="init.jsp" %><%

//기본키
String path = m.rs("path");
int width = m.ri("v_width");
int height = m.ri("v_height");

if("".equals(path)) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }
if(1 > width) width = 640;
if(1 > height) height = 360;

String videoUrl = siteinfo.s("cdn_url").indexOf("{mp4}") > 0 ? m.replace(siteinfo.s("cdn_url"), "{mp4}", path) : siteinfo.s("cdn_url") + path;

//출력
p.setLayout("blank");
p.setBody("video.cdn_preview");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
p.setVar("video_url", videoUrl);
p.display();

%>