<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
WordFilterDao wordFilterDao = new WordFilterDao();

//폼체크
f.addElement("course_id", null, "hname:'과정', required:'Y'");
f.addElement("subject", null, "hname:'제목', required:'Y'");
f.addElement("secret_yn", null, "hname:'비밀글 여부'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
f.addElement("point", null, "hname:'점수', required:'Y'");

//등록
if(m.isPost() && f.validate()) {
	//변수
	int courseId = f.getInt("course_id");
	int cuid = courseUser.getOneInt("SELECT id FROM " + courseUser.table + " WHERE user_id = " + userId + " AND course_id = " + courseId + " AND status IN (1, 3)");
	int bid = board.getOneInt("SELECT id FROM " + board.table + " WHERE course_id = " + courseId + " AND code = 'review' AND status = 1");

	//제한
	if(0 == courseId) { m.jsAlert(_message.get("alert.common.required_key")); return; }
	if(0 == cuid) { m.jsAlert(_message.get("alert.course_user.nodata")); return; }
	if(0 == bid) { m.jsAlert(_message.get("alert.board.nodata")); return; }

	//제한-비속어
	if(wordFilterDao.check(f.get("subject")) || wordFilterDao.check(f.get("content"))) {
		m.jsAlert("비속어가 포함되어 등록할 수 없습니다.");
		return;
	}

	int newId = post.getSequence();
	post.item("id", newId);
	post.item("site_id", siteId);
	post.item("course_id", courseId);
	post.item("course_user_id", cuid);
	post.item("board_cd", "review");
	post.item("board_id", bid);
	post.item("thread", post.getLastThread());
	post.item("depth", "A");
	post.item("user_id", userId);
	post.item("writer", userName);
	post.item("notice_yn", f.get("notice_yn", "N"));
	post.item("secret_yn", f.get("secret_yn", "N"));
	post.item("subject", f.get("subject"));
	post.item("content", f.get("content"));
	post.item("point", f.getInt("point"));
	post.item("hit_cnt", 0);
	post.item("comm_cnt", 0);
	post.item("proc_status", 0);
	post.item("reg_date", m.time("yyyyMMddHHmmss"));
	post.item("status", 1);
	if(!post.insert()) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	//이동
	m.jsReplace("review_list.jsp?" + m.qs("pid"), "parent");
	return;
}

//목록-과정
//courseUser.d(out);
DataSet clist = courseUser.query(
	"SELECT a.start_date, a.end_date, c.* "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId
	+ " WHERE a.user_id = '" + userId + "' AND a.status IN (1,3)"
	+ " ORDER BY a.start_date desc, c.course_nm asc "
);
if(1 > clist.size()) { m.jsError(_message.get("alert.course_user.nodata_list")); return; }
while(clist.next()) {
	clist.put("start_date_conv", m.time(_message.get("format.date.dot"), clist.s("start_date")));
	clist.put("end_date_conv", m.time(_message.get("format.date.dot"), clist.s("end_date")));
	clist.put("course_nm_conv", m.cutString(clist.s("course_nm"), 56));
}

//출력
p.setLayout(ch);
p.setBody("course.review_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,pid"));
p.setVar("form_script", f.getScript());

p.setLoop("course_list", clist);
p.display();

%>