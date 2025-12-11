<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
LessonDao lesson = new LessonDao();

//목록
DataSet info = lesson.find("id = " + m.ri("id"));
if(!info.next()) { m.jsErrClose("차시 정보를 찾을 수 없습니다."); return; }

if("".equals(info.s("mobile_a")) && "".equals(info.s("mobile_i"))) { m.jsErrClose("영상 정보를 찾을 수 없습니다."); return;  }
info.put("last_time", 0);
info.put("study_time", 0);

//출력
p.setLayout(null);
p.setBody("content.preview_mobile");
p.setVar(info);
p.display();

%>