<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//기본키
String clientUserId = m.rs("user_id"); // 정상적인 진도시 : COURSE_USER.id + _ + COURSE_MODULE.module_id // 맛보기 : 12자리랜덤값
int cuid = m.ri("uval0"); // COURSE_USER.id
int lid = m.ri("uval1"); // COURSE_LESSON.lesson_id
int chapter = m.ri("uval2"); // COURSE_LESSON.chapter
int studyTime = m.ri("play_time");
int currTime = m.ri("last_play_at");
if(clientUserId.indexOf("_") == -1 || cuid == 0 || lid == 0 || currTime == 0) {
	m.log("kollus", "Error : userId=" + clientUserId + ", cuid=" + cuid + ", lid=" + lid + ", studyTime=" + studyTime + ", currTime=" + currTime);
	return;
}

//메일관련 study_time 이 누적되야하는데 현재 플레이 창이 열리고 플레이 된 총시간이 study_time 으로 누적되서 데이터가 넘어온다. 정확한 study_time 이 아니여서
//카테노이드에 30초마다 check_api.jsp 를 호출하므로 studyTime을 30초로 세팅
if(studyTime > 0) studyTime = 30;

//추가 요청주신 종료시 발송하는 callback을 확인할수 있는 별도 값은 현재 따로 없는 상태입니다.
//관련하여 내부 협의 후 추가 회신드리도록 하겠습니다.

//플레이어 종료시 flag 값이 넘어오게 되면. preStudyTime = 0 으로 변경해서 저장해야 한다.

//객체
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
CourseUserDao courseUser = new CourseUserDao();

courseProgress.setStudyTime(studyTime);
courseProgress.setCurrTime(currTime);
int ret = courseProgress.updateProgress(cuid, lid, chapter);

m.log("kollus", "userId=" + clientUserId + ", cuid=" + cuid + ", lid=" + lid + ", studyTime=" + studyTime + ", currTime=" + currTime + ", ret=" + ret);

//수강생 정보 업데이트
if(ret == 2) {
	courseUser.setProgressRatio(cuid);
	courseUser.updateScore(cuid, "progress"); //점수일괄업데이트
	courseUser.closeUser(cuid, userId);
}

%>