<%@ page contentType="text/html; charset=utf-8" %><%@ page import="org.json.*" %><%@ include file="init.jsp" %><%

String videoKey = siteinfo.s("video_key");

//콜백 처리
String data = m.rs("data");
if(!"".equals(data)) {
	Json j = new Json(data);
	String errCode = j.getString("//uploadInfo/errorInfo/errorCode");
	if(!"None".equals(errCode)) {
		String errMsg = j.getString("//uploadInfo/errorInfo/errorMessage");
		Malgn.errorLog("{Video.callback} videoKey:" + videoKey + ", this.errCode:" + errCode + ", this.errMsg:" + errMsg);
		m.jsAlert("동영상 업로드가 실패하였습니다.:" + errMsg);
	}
	return;
}

String packageId = m.rs("package_id");
if("".equals(packageId)) { m.jsError("배포패키지 아이피는 필수 항목입니다."); return; }

//객체
WecandeoDao wecandeo = new WecandeoDao(videoKey);

DataSet folders = wecandeo.getFolders();
String folderId = wecandeo.getFolderId(folders, loginId);

DataSet info = wecandeo.getUploadToken();
if(!info.next()) { m.jsError("업로드 주소를 가져올 수 없습니다."); return; }

info.put("upload_url", info.s("uploadUrl") + "?token=" + info.s("token"));
info.put("status_url", info.s("uploadUrl") + "/uploadStatus.json?token=" + info.s("token"));

//출력
p.setLayout(ch);
p.setBody("video.wecandeo_upload");
p.setVar("p_title", "동영상 업로드");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
if("".equals(folderId)) {
	p.setLoop("folders", folders);
} else {
	p.setVar("folder_id", folderId);
}
p.setVar("package_id", packageId);
p.setVar(info);
p.display();

%>