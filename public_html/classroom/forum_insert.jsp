<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

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

boolean isOpen = !isReady && !isEnd && "I".equals(progress) && !info.b("confirm_yn");
if(!isOpen) { m.jsError(_message.get("alert.common.abnormal_access")); return; }

//폼객체
f.addElement("subject", null, "hname:'제목', required:'Y'");
f.addElement("post_file", null, "hname:'첨부파일'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");

if(m.isPost() && f.validate()) {

	forumPost.item("forum_id", id);
	forumPost.item("course_user_id", cuid);
	forumPost.item("course_id", courseId);
	forumPost.item("user_id", userId);
	forumPost.item("site_id", siteId);
	forumPost.item("writer", userName);
	forumPost.item("subject", f.get("subject"));
	forumPost.item("content", f.get("content"));

	File f1 = f.saveFile("post_file");
	if(f1 != null) {
		forumPost.item("post_file", f.getFileName("post_file"));
	}

	forumPost.item("hit_cnt", 0);
	forumPost.item("mod_date", now);
	forumPost.item("reg_date", now);
	forumPost.item("status", 1);

	if(!forumPost.insert()) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	//포럼유저
	if(0 < forumUser.findCount("forum_id = " + id + " AND course_user_id = " + cuid + "")) {
		forumUser.item("post_cnt", forumPost.findCount("status= 1 AND forum_id = " + id + " AND course_user_id = " + cuid));
		forumUser.item("mod_date", now);
		if(!forumUser.update("forum_id = " + id + " AND course_user_id = " + cuid + "")) {
			m.jsAlert(_message.get("alert.common.error_modify")); return;
		}
	} else {
		forumUser.item("forum_id", id);
		forumUser.item("course_user_id", cuid);
		forumUser.item("course_id", courseId);
		forumUser.item("user_id", userId);
		forumUser.item("site_id", siteId);
		forumUser.item("post_cnt", 1);
		forumUser.item("marking_score", 0);
		forumUser.item("score", 0);
		forumUser.item("feedback", "");
		forumUser.item("submit_yn", "Y");
		forumUser.item("confirm_yn", "N");
		forumUser.item("mod_date", now);
		forumUser.item("reg_date", now);
		forumUser.item("status", 1);
		if(!forumUser.insert()) { m.jsAlert(_message.get("alert.common.error_insert")); return; }
	}

	m.jsReplace("forum_view.jsp?cuid=" + cuid + "&id=" + id, "parent");
	return;
}

//출력

p.setLayout(ch);
p.setBody("classroom.forum_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("pid"));
p.setVar("form_script", f.getScript());

p.setVar("forum", info);
p.display();

%>