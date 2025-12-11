<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//if(!m.isPost()) return;

int cuid = m.ri("cuid");
int lid = m.ri("lid");
int chapter = m.ri("chapter");
int studyTime = m.ri("study_time");
String currPage = m.rs("curr_page");

if(cuid == 0 || chapter == 0 || lid == 0) return;

//객체
CourseProgressDao courseProgress = new CourseProgressDao(siteId);
CourseUserDao courseUser = new CourseUserDao();

courseProgress.setStudyTime(studyTime);
courseProgress.setCurrPage(currPage);
int ret = courseProgress.updateProgress(cuid, lid, chapter);

//수강생 정보 업데이트
if(ret == 2) {
	courseUser.setProgressRatio(cuid);
	courseUser.updateScore(cuid, "progress"); //점수일괄업데이트
	courseUser.closeUser(cuid, userId);
}

out.print("<script>");
out.print("try { top.opener.location.reload(); } catch(e) {}");
out.print("</script>");

%>