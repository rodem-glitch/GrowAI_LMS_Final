<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//기본키
String ek = m.rs("ek");
if("".equals(ek) || !m.encrypt(m.rs("id") + m.time("yyyyMMdd")).equals(ek)) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//객체
FileDao file = new FileDao();
FileLogDao fileLog = new FileLogDao(request);

//정보
DataSet info = file.find("id = " + id + "");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
String path = m.getUploadPath(info.s("filename"));
info.put("filepath", path);
info.put("site_id", siteId);

//권한
if("post".equals(info.s("module"))) {
	//객체
	PostDao post = new PostDao();
	BoardDao board = new BoardDao();

	//게시판권한
	int bid = post.getOneInt("SELECT board_id FROM " + post.table + " WHERE id = " + info.s("module_id") + " AND site_id = " + siteId + " AND display_yn = 'Y' AND status = 1");
	if(1 > bid) { m.jsError(_message.get("alert.post.nodata")); return; }
	if(!board.accessible("download", bid, userGroups, userKind)) {
		if(userId == 0) {
			m.jsAlert(_message.get("alert.member.required_login"));
			m.jsReplace(auth.loginURL + "?returl=" + m.urlencode(null != request.getHeader("referer") ? request.getHeader("referer") : ""), "parent");
			return;
		} else {
			m.jsError(_message.get("alert.common.permission_download"));
			return;
		}
	}

} else if("lesson".equals(info.s("module"))) {
	//기본키
	int cuid = m.ri("cuid");
	String cek = m.rs("cek");
	if(1 > userId || 1 > cuid || "".equals(cek) || !m.encrypt(cuid + "" + id + info.s("module_id") + m.time("yyyyMMdd")).equals(cek)) {
		m.jsError(_message.get("alert.common.abnormal_access"));
		return;
	}

	//객체
	CourseUserDao courseUser = new CourseUserDao();

	//권한
	//if(!lesson.accessible(info.i("module_id"), userId, siteId)) { m.jsError(_message.get("alert.common.permission_download")); return; }
	if(!courseUser.accessible(cuid, userId, siteId)) { m.jsError(_message.get("alert.common.permission_download")); return; }
}

file.updateDownloadCount(m.ri("id"));

//다운로드
File f1 = new File(path);
if(f1.exists()) {
	if(!fileLog.addLog(userId, info)) { }
	m.download(path, info.s("filename"), 500);
} else {
	m.jsError(_message.get("alert.common.nofile"));
	return;
}

%>