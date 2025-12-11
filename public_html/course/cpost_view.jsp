<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
int cid = m.ri("cid");
if(id == 0 || cid == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
UserDao user = new UserDao();

DataSet info = clPost.query(
	"SELECT a.*, b.board_type, u.login_id "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1 "
	+ " WHERE a.id = " + id + " AND a.display_yn = 'Y' AND a.status = 1 AND a.course_id = " + cid
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
//제한
if(info.b("secret_yn") && userId != info.i("user_id")) { m.jsError(_message.get("alert.post.private")); return; }
info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
info.put("reg_date_conv", m.time(_message.get("format.date.dot"), info.s("reg_date")));
info.put("hit_cnt_conv", m.nf(info.getInt("hit_cnt")));
info.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(info.s("writer")) : info.s("writer"));

//쿠키
String[] readArray = m.getCookie("CREAD").split("\\,");
if(!m.inArray(""+id + "/" + userId, readArray)) {
	clPost.updateHitCount(id);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id + "/" + userId : tmp + "," + id + "/" + userId;
	m.setCookie("CREAD", tmp, 3600 * 24);
}

//이전/다음글
clPost.addWhere("a.status = 1");
clPost.addWhere("a.course_id = " + cid + "");
clPost.addWhere("b.code = 'review'");
DataSet prev = clPost.getPrevPost(info.i("board_id"), info.i("thread"), info.s("depth"));
DataSet next = clPost.getNextPost(info.i("board_id"), info.i("thread"), info.s("depth"));
if(prev.next()) {
	prev.put("subject_conv", m.cutString(prev.s("subject"), 50));
	prev.put("reg_date_conv", m.time(_message.get("format.date.dot"), prev.s("reg_date")));
}
if(next.next()) {
	next.put("subject_conv", m.cutString(next.s("subject"), 50));
	next.put("reg_date_conv", m.time(_message.get("format.date.dot"), next.s("reg_date")));
}

//출력
p.setLayout("blank");
p.setBody("course.cpost_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);

p.setVar("prev", prev);
p.setVar("next", next);
p.display();

%>