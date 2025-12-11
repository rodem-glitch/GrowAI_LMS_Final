<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int mid = m.ri("mid");
int lid = m.ri("lid");
String mode = m.rs("mode");

if(mid == 0 || lid == 0 || "".equals(mode)) { m.jsAlert(_message.get("alert.common.required_key")); return; }

//객체
LessonDao lesson = new LessonDao();

//출력
p.setLayout(ch);
p.setBody("minitalk.index");

p.setVar("channel", lesson.getChannelId(siteinfo.s("ftp_id"), siteId, mid, lid, mode));
p.setVar("nickname", lesson.getNickname(loginId, userIp));

p.display();

%>