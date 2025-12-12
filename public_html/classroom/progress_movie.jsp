<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

if(userId == 0) return;

boolean isTimer = "Y".equals(m.rs("timer"));

int cuid = m.ri("cuid");
int chapter = m.ri("chapter");
int lid = m.ri("lid");
int vid = m.ri("vid"); //다중영상일 때 서브영상 id
if(vid == 0) vid = m.ri("uservalue3"); //콜러스 등 외부 플레이어 대비
int currTime = m.ri("curr_time");
int studyTime = m.ri("study_time");

//기본키
if(cuid == 0 || lid == 0 || chapter == 0 || currTime <= 0 || studyTime <= 0) return;
//if(studyTime > 300) studyTime = 300;

//객체
CourseUserDao courseUser = new CourseUserDao();
int ret = 0;

if(vid > 0) {
	//다중영상 차시: 서브영상 진도를 저장하고 합산하여 부모 차시 진도를 갱신합니다.
	CourseProgressVideoDao courseProgressVideo = new CourseProgressVideoDao(siteId);
	courseProgressVideo.setStudyTime(studyTime);
	courseProgressVideo.setCurrTime(currTime);
	ret = courseProgressVideo.updateVideoProgress(cuid, lid, vid, chapter);
} else {
	//기존 단일영상 차시 로직 그대로 유지
	CourseProgressDao courseProgress = new CourseProgressDao(siteId);
	courseProgress.setStudyTime(studyTime);
	courseProgress.setCurrTime(currTime);
	ret = courseProgress.updateProgress(cuid, lid, chapter);
}

m.log("movie", "userId=" + userId + ", cuid=" + cuid + ", lid=" + lid + ", vid=" + vid + ", studyTime=" + studyTime + ", currTime=" + currTime + ", ret=" + ret);

//수강생 정보 업데이트
if(ret == 2) {
	courseUser.setProgressRatio(cuid);
	courseUser.updateScore(cuid, "progress"); //점수일괄업데이트
	courseUser.closeUser(cuid, userId);
}

out.print(ret);

%>
