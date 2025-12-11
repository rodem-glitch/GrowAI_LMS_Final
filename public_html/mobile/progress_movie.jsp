<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//if(!m.isPost()) return;

boolean isTimer = "Y".equals(m.rs("timer"));

int cuid = m.ri("cuid");
int lid = m.ri("lid");
int chapter = m.ri("chapter");
int currTime = m.parseInt(m.replace(m.nf(m.parseDouble(m.rs("curr_time")), 0), ",", ""));
int studyTime = m.parseInt(m.replace(m.nf(m.parseDouble(m.rs("study_time")), 0), ",", ""));
int lastTime = m.parseInt(m.replace(m.nf(m.parseDouble(m.rs("last_time")), 0), ",", ""));		//진행된 최대 위치

//객체
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
CourseUserDao courseUser = new CourseUserDao();

courseProgress.setStudyTime(studyTime);
courseProgress.setCurrTime(currTime);
int ret = courseProgress.updateProgress(cuid, lid, chapter);

//수강생 정보 업데이트
if(ret == 2) {
	courseUser.setProgressRatio(cuid);
	courseUser.updateScore(cuid, "progress"); //점수일괄업데이트
	courseUser.closeUser(cuid, userId);
}

if(!isTimer || ret == 2) {
	out.print("<script>");
	out.print("try { top.opener.location.reload(); } catch(e) {}");
	out.print("</script>");
}

%>