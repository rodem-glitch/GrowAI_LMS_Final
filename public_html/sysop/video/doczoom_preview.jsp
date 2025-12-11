<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
LessonDao lesson = new LessonDao();
ContentDao content = new ContentDao();
DoczoomDao doczoom = new DoczoomDao();


//컨텐츠 목록을 가져올 때 지정할 조건값들. Integer 변수에 null을 지정하면 해당 조건은 무시됩니다.
String contentID = m.rs("key");
String userID = "malgn_" + siteinfo.s("ftp_id");

//doczoom.setDebug(out);
DataSet info = doczoom.getContentInfo(contentID);
if(info.next()) {
	String SessionID = doczoom.addContentViewerLoginSharedSessionData(userID, contentID, 10);
	if(SessionID != null) {
		m.redirect("https://cms.malgnlms.com/DocZoomMobile/doczoomviewer.asp?MediaID=" + contentID + "&sessionID=" + SessionID);
		return;
	}
}


//출력
p.setLayout("sysop");
p.setBody("video.doczoom_preview");
p.setVar("p_title", "문서 콘텐츠 관리");
p.display();

%>