<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

int cuid = m.ri("cuid");
int chapter = m.ri("chapter");
int lid = m.ri("lid");
int currTime = m.parseInt(m.replace(m.nf(m.parseDouble(m.rs("curr_time")), 0), ",", ""));
int studyTime = m.parseInt(m.replace(m.nf(m.parseDouble(m.rs("study_time")), 0), ",", ""));
int lastTime = m.parseInt(m.replace(m.nf(m.parseDouble(m.rs("last_time")), 0), ",", ""));		//진행된 최대 위치

//기본키
if(cuid == 0 || lid == 0  || chapter == 0 || currTime <= 0) {
	p.setVar("error_code", "0001");
	p.setVar("error_msg", "기본키는 반드시 지정해야 합니다.");
	p.fetch("../html/mobile/api.xml");
	return;
}

p.setVar("error_code", "0");
p.fetch("../html/mobile/api.xml");

%>