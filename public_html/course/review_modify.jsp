<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
WordFilterDao wordFilterDao = new WordFilterDao();

//정보
DataSet info = post.query(
	" SELECT a.*, c.course_nm, c.step, c.year, cu.start_date, cu.end_date "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.code = 'review' "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
	+ " INNER JOIN " + courseUser.table + " cu ON a.course_user_id = cu.id AND cu.site_id = " + siteId + " "
	+ " WHERE a.id = ? AND a.site_id = " + siteId + " AND a.display_yn = 'Y' AND a.status = 1"
	, new Object[] { id }
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
info.put("start_date_conv", m.time("yyyy.MM.dd", info.s("start_date")));
info.put("end_date_conv", m.time("yyyy.MM.dd", info.s("end_date")));

//제한
if(info.i("user_id") != userId) { m.jsError(_message.get("alert.common.permission_modify")); return; }

//폼체크
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("secret_yn", info.s("secret_yn"), "hname:'비밀글 여부'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
f.addElement("point", info.s("point"), "hname:'점수', required:'Y'");

//등록
if(m.isPost() && f.validate()) {
	//변수
	int courseId = f.getInt("course_id");
	int cuid = courseUser.getOneInt("SELECT id FROM " + courseUser.table + " WHERE user_id = " + userId + " AND course_id = " + courseId + " AND status IN (1, 3)");
	int bid = board.getOneInt("SELECT id FROM " + board.table + " WHERE course_id = " + courseId + " AND code = 'review' AND status = 1");

	//제한-비속어
	if(wordFilterDao.check(f.get("subject")) || wordFilterDao.check(f.get("content"))) {
		m.jsAlert("비속어가 포함되어 수정할 수 없습니다.");
		return;
	}

	//제한
	post.item("secret_yn", f.get("secret_yn", "N"));
	post.item("subject", f.get("subject"));
	post.item("content", f.get("content"));
	post.item("point", f.getInt("point"));
	if(!post.update("id = " + id + "")) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	//이동
	m.jsReplace("review_view.jsp?" + m.qs(), "parent");
	return;
}

//출력
p.setLayout(ch);
p.setBody("course.review_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,pid"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setVar("modify", true);
p.display();

%>