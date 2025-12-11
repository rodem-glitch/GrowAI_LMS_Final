<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ClPostDao clPost = new ClPostDao();
ClBoardDao clBoard = new ClBoardDao();
CourseDao course = new CourseDao();
CourseTargetDao courseTarget = new CourseTargetDao();

//정보
DataSet info = clPost.query(
	"SELECT a.*, c.course_nm, c.step, c.year "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.code = 'review' "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
	+ " WHERE a.id = ? AND a.display_yn = 'Y' AND a.status = 1 "
	+ ("N".equals(siteconfig.s("target_review_yn")) ? (" AND (c.target_yn = 'N'" + (!"".equals(userGroups) ? " OR EXISTS (SELECT 1 FROM " + courseTarget.table + " WHERE course_id = c.id AND group_id IN (" + userGroups + "))" : "") + ")") : "")
	, new Object[] {id}
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
if(info.b("secret_yn")) {
	if("Y".equals(SiteConfig.s("review_reply_yn"))) {
		if(!(userId == info.i("user_id") || "S".equals(userKind) || "A".equals(userKind))) { m.jsError(_message.get("alert.post.private")); return; }
	} else {
		if(userId != info.i("user_id")) { m.jsError(_message.get("alert.post.private")); return; }
	}
}

info.put("reg_date_conv", m.time(_message.get("format.date.dot"), info.s("reg_date")));
info.put("subject", m.htt(info.s("subject")));
info.put("hit_cnt_conv", m.nf(info.i("hit_cnt")));
info.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(info.s("writer")) : info.s("writer"));

//쿠키
String[] readArray = null;
readArray = m.getCookie("CREAD").split("\\,");
if(!m.inArray(""+id + "/" + userId, readArray)) {
	clPost.updateHitCount(id);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id + "/" + userId : tmp + "," + id + "/" + userId;
	m.setCookie("CREAD", tmp, 3600 * 24);
}

//이전/다음글
/*
clPost.appendWhere("a.status = 1");
clPost.appendWhere("b.code = 'review'");
if(!"".equals(f.get("s_field"))) clPost.appendSearch(m.rs("s_field"), m.rs("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	Vector<String> v = new Vector<String>();
	v.add("a.subject LIKE '%" + m.rs("s_keyword") + "%'");
	v.add("a.content LIKE '%" + m.rs("s_keyword") + "%'");
	v.add("a.writer LIKE '%" + m.rs("s_keyword") + "%'");
	clPost.appendWhere("(" + m.join(" OR ", v.toArray()) + ")");
}
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
*/

//출력
p.setLayout(ch);
p.setBody("course.review_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);

//p.setVar("prev", prev);
//p.setVar("next", next);
p.setVar("modify_block", info.i("user_id") != 0 && info.i("user_id") == userId);
p.setVar("reply_block", "Y".equals(SiteConfig.s("review_reply_yn")));
p.display();

%>