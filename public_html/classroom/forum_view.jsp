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
	+ ", u.user_id, u.submit_yn, u.score, u.marking_score, u.confirm_yn, u.mod_date, u.feedback "
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
if("1".equals(info.s("apply_type"))) { //기간
	info.put("start_date_conv", m.time(_message.get("format.datetime.dot"), info.s("start_date")));
	info.put("end_date_conv", m.time(_message.get("format.datetime.dot"), info.s("end_date")));

	isReady = 0 > m.diffDate("I", info.s("start_date"), now);
	isEnd = 0 < m.diffDate("I", info.s("end_date"), now);

	info.put("apply_type_1", true);
	info.put("apply_type_2", false);
} else if("2".equals(info.s("apply_type"))) { //차시
	info.put("apply_conv", info.i("chapter") == 0 ? _message.get("classroom.module.before_study") : _message.get("classroom.module.after_study", new String[] { "chapter=>" + info.i("chapter") }));
	if(info.i("chapter") > 0 && 0 == courseProgress.findCount("course_id = " + courseId + " AND chapter = " + info.i("chapter") + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;

	info.put("apply_type_1", false);
	info.put("apply_type_2", true);
}

String status = "-";
if(info.b("submit_yn")) status = _message.get("classroom.module.status.submit");
else if("W".equals(progress) || isReady) status = _message.get("classroom.module.status.waiting");
else if("E".equals(progress) || isEnd) status = _message.get("classroom.module.status.end");
else if("I".equals(progress) && info.i("user_id") != 0) status = _message.get("classroom.module.status.writing");
else status = "-";
info.put("status_conv", status);

info.put("reg_date_conv", info.b("submit_yn") ? m.time(_message.get("format.datetime.dot"), info.s("reg_date")) : _message.get("classroom.module.status.nosubmit"));
info.put("result_score", info.b("submit_yn")
		? (info.b("confirm_yn") ? info.d("marking_score") + _message.get("classroom.module.score") + " (" + _message.get("classroom.module.score_converted") + " : " + info.d("score") + _message.get("classroom.module.score") + ")" : _message.get("classroom.module.status.evaluating"))
		: "-"
);

boolean isOpen = !isReady && !isEnd && "I".equals(progress) && !info.b("confirm_yn");
info.put("open_block", isOpen);

info.put("forum_content_conv", m.htt(info.s("forum_content")));
info.put("forum_file_conv", m.encode(info.s("forum_file")));
info.put("forum_file_ek", m.encrypt(info.s("forum_file") + m.time("yyyyMMdd")));
info.put("forum_file_ext", file.getFileIcon(info.s("forum_file")));

info.put("post_cnt_conv", m.nf(info.i("post_cnt")));


//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setTable(
	forumPost.table + " a "
	+ " INNER JOIN " + user.table + " b ON a.user_id = b.id "
);
lm.setFields("a.*, b.user_nm");
lm.setListNum(5);
lm.addWhere("a.status = 1");
lm.addWhere("a.forum_id = '" + id + "'");
lm.addWhere("a.course_id = '" + courseId + "'");
lm.addWhere("EXISTS (SELECT 1 FROM " + courseUser.table + " WHERE a.course_user_id = id AND status IN (1,3))");
lm.setOrderBy("a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
//	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
	list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
}

//출력
p.setLayout(ch);
p.setBody("classroom.forum_view");
p.setVar("list_query", m.qs("pid"));
p.setVar(info);

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.display();

%>