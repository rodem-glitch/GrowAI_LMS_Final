<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

if(userId == 0) return;

boolean isTimer = "Y".equals(m.rs("timer"));

int cuid = m.ri("cuid");
int chapter = m.ri("chapter");
int lid = m.ri("lid");
int currTime = m.ri("curr_time");
int studyTime = m.ri("study_time");

//기본키
if(cuid == 0 || lid == 0 || chapter == 0 || currTime <= 0 || studyTime <= 0) return;
//if(studyTime > 300) studyTime = 300;

//객체
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
CourseUserDao courseUser = new CourseUserDao();

courseProgress.setStudyTime(studyTime);
courseProgress.setCurrTime(currTime);
int ret = courseProgress.updateProgress(cuid, lid, chapter);

m.log("movie", "userId=" + userId + ", cuid=" + cuid + ", lid=" + lid + ", studyTime=" + studyTime + ", currTime=" + currTime + ", ret=" + ret);

//수강생 정보 업데이트
if(ret == 2) {
	courseUser.setProgressRatio(cuid);
	courseUser.updateScore(cuid, "progress"); //점수일괄업데이트
	courseUser.closeUser(cuid, userId);
}

out.print(ret);

%>