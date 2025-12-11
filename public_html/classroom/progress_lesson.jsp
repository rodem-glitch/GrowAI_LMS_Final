<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

if(userId == 0) return;

int cuid = m.ri("cuid");
int chapter = m.ri("chapter");
int lid = m.ri("lid");
int studyTime = m.ri("study_time");
int currTime = m.ri("curr_time");
String currPage = m.rs("curr_page");
String otid = m.rs("otid");

//m.log("lesson", "progress_lesson loaded");

if(cuid == 0 || chapter == 0 || lid == 0) return;
if(studyTime > 30) studyTime = 30;

//객체
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
CourseSessionDao courseSession = new CourseSessionDao(siteId);
CourseUserDao courseUser = new CourseUserDao();

//제한
if(!"".equals(otid) && !courseSession.verifyOnetime(otid)) { out.print("-99"); return; }

courseProgress.setStudyTime(studyTime);
courseProgress.setCurrPage(currPage);
if(currTime > 0) courseProgress.setCurrTime(currTime);
int ret = courseProgress.updateProgress(cuid, lid, chapter);

m.log("lesson", "userId=" + userId + ", cuid=" + cuid + ", lid=" + lid + ", studyTime=" + studyTime + ", currPage=" + currPage + ", ret=" + ret);

//수강생 정보 업데이트
if(ret == 2) {
	courseUser.setProgressRatio(cuid);
	courseUser.updateScore(cuid, "progress"); //점수일괄업데이트
	courseUser.closeUser(cuid, userId);
}

out.print(ret);

%>