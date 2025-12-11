<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int pid = m.ri("pid");
int id = m.ri("id");
if(id == 0 || pid == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ForumDao forum = new ForumDao();
ForumUserDao forumUser = new ForumUserDao();
ForumPostDao forumPost = new ForumPostDao();
CourseProgressDao courseProgress = new CourseProgressDao();
FileDao file = new FileDao();

//정보
DataSet info = courseModule.query(
	"SELECT a.*, f.forum_nm, f.forum_file, f.content forum_content "
	+ ", u.user_id, u.submit_yn, u.score, u.marking_score, u.confirm_yn, u.mod_date "
	+ ", u.post_cnt "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + forum.table + " f ON a.module_id = f.id AND f.status != -1 AND f.id = " + id + " "
	+ " LEFT JOIN " + forumUser.table + " u ON "
		+ "u.forum_id = a.module_id AND u.course_user_id = " + cuid + " "
	+ " WHERE a.status = 1 AND a.module = 'forum' "
	+ " AND a.course_id = " + courseId + " AND f.site_id = " + siteId + ""
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; };

//포맷팅
boolean isReady = false; //대기
boolean isEnd = false; //완료
if("1".equals(info.s("apply_type"))) { //시작일
	info.put("start_date_conv", m.time(_message.get("format.datetime.dot"), info.s("start_date")));
	info.put("end_date_conv", m.time(_message.get("format.datetime.dot"), info.s("end_date")));

	isReady = 0 > m.diffDate("I", info.s("start_date"), now);
	isEnd = 0 < m.diffDate("I", info.s("end_date"), now);

	info.put("apply_type_1", true);
	info.put("apply_type_2", false);
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + info.i("chapter") }));
	if(info.i("chapter") > 0 && 0 == courseProgress.findCount("course_id = " + courseId + " AND chapter = " + info.i("chapter") + " AND complete_yn = 'Y'")) isReady = true;

	info.put("apply_type_1", false);
	info.put("apply_type_2", true);
}

//정보
DataSet pinfo = forumPost.query(
	"SELECT a.*, u.score, u.confirm_yn "
	+ " FROM " + forumPost.table + " a "
	+ " LEFT JOIN " + forumUser.table + " u ON a.forum_id = u.forum_id AND u.course_user_id = a.course_user_id "
	+ " WHERE a.status = 1 AND a.id = " + pid + " "
	+ " AND a.course_id = '" + courseId + "' "
);
if(!pinfo.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

boolean isOpen = !isReady && !isEnd && "I".equals(progress) && !info.b("confirm_yn") && pinfo.i("course_user_id") == cuid;
info.put("open_block", isOpen);

if(isOpen) {

	//삭제
	if("del".equals(m.rs("mode"))) {
		if(!"".equals(pinfo.s("post_file"))) {
			forumPost.item("post_file", "");
			if(!forumPost.update("id = " + pid + "")) {
				m.jsAlert(_message.get("alert.file.error_delete")); return;
			}
			m.delFileRoot(m.getUploadPath(pinfo.s("post_file")));
		}
		return;
	}


	//삭제
	if("pdel".equals(m.rs("mode"))) {
		forumPost.item("status", -1);
		if(!forumPost.update("id = " + pid + "")) { m.jsError(_message.get("alert.common.error_delete")); return; }

		forumUser.item("post_cnt", forumPost.findCount("status= 1 AND forum_id = " + id + " AND course_user_id = " + cuid + ""));
		forumUser.item("mod_date", now);
		if(!forumUser.update("forum_id = " + id + " AND course_user_id = " + cuid + "")) {
			m.jsError(_message.get("alert.common.error_delete")); return;
		}

		m.jsReplace("forum_view.jsp?" + m.qs("pid, mode"), "parent");

		return;
	}

	//폼입력
	f.addElement("subject", pinfo.s("subject"), "hname:'제목', required:'Y'");
	f.addElement("post_file", null, "hname:'첨부파일'");
	f.addElement("content", null, "hname:'내용', allowhtml:'Y'");

	//수정
	if(m.isPost() && f.validate()) {

		forumPost.item("subject", f.get("subject"));
		forumPost.item("content", f.get("content"));

		File f1 = f.saveFile("post_file");
		if(f1 != null) {
			forumPost.item("post_file", f.getFileName("post_file"));
			if(!"".equals(pinfo.s("post_file"))) m.delFileRoot(m.getUploadPath(pinfo.s("post_file")));
		}

		forumPost.item("mod_date", now);
		if(!forumPost.update("id = " + pid + "")) { m.jsAlert(_message.get("alert.common.error_modify")); return; }

		//갱신
		forumUser.execute(
			"UPDATE " + forumUser.table + " SET "
			+ " mod_date = '" + now + "' "
			+ " WHERE forum_id = " + id + " AND course_user_id = " + cuid + " "
		);

		m.jsReplace("forum_view.jsp?" + m.qs("pid, mode"), "parent");
		return;
	}
}

pinfo.put("post_file_conv", m.encode(pinfo.s("post_file")));
pinfo.put("post_file_ek", m.encrypt(pinfo.s("post_file") + m.time("yyyyMMdd")));
pinfo.put("post_file_ext", file.getFileIcon(pinfo.s("post_file")));
pinfo.put("reg_date_conv", m.getTimeString("yyyy.MM.dd HH:mm", pinfo.s("reg_date")));
pinfo.put("content_conv", m.htt(pinfo.s("content")));

//갱신
String[] readArray = m.getCookie("CFREAD").split("\\,");
if(!m.inArray(""+pid + "/" + userId, readArray)) {
	forumPost.updateHitCount(pid);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + pid + "/" + userId : tmp + "," + pid + "/" + userId;
	m.setCookie("CFREAD", tmp, 3600 * 24);
}

//출력
p.setLayout(ch);
p.setBody("classroom.forum_read");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("pid, mode"));
p.setVar("form_script", f.getScript());

p.setVar("forum", info);
p.setVar("post", pinfo);

p.display();

%>