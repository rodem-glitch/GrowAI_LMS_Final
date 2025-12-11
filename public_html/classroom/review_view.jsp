<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
ClFileDao clFile = new ClFileDao();

int boardId = clBoard.getOneInt("SELECT id FROM " + clBoard.table + " WHERE course_id = " + courseId + " AND board_type = 4");

if(boardId == 0) { m.jsError(_message.get("alert.board.nodata")); return; }

DataSet info = clPost.find("id = " + id + " AND display_yn = 'Y' AND status = 1 AND course_id = " + courseId + " AND board_id = " + boardId);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//삭제
if("del".equals(m.rs("mode"))) {
	if(cuid != info.i("course_user_id")) { m.jsError(_message.get("alert.common.abnormal_access")); return; }
	clPost.item("status", -1);
	if(!clPost.update("id = " + id)) { m.jsError(_message.get("alert.common.error_delete")); return; }
	m.jsReplace("review.jsp?" + m.qs("id, mode"));
	return;
}

String on = "<img src='/html/images/common/star_on.jpg'>";
String off = "<img src='/html/images/common/star_off.jpg'>";
//info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
info.put("reg_date_conv", m.time(_message.get("format.date.dot"), info.s("reg_date")));
info.put("hit_cnt_conv", m.nf(info.i("hit_cnt")));
info.put("point", m.repeatString(on , info.i("point")) + m.repeatString(off , 5 - info.i("point")));
info.put("modify_block", info.i("course_user_id") == cuid);

//쿠키체크(Update HitCount)
String[] readArray = m.getCookie("READ").split("\\,");
if(!m.inArray(""+id + "/" + userId, readArray)) {
	clPost.updateHitCount(id);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id + "/" + userId : tmp + "," + id + "/" + userId;
	m.setCookie("READ", tmp, 3600 * 24);
}

//이전다음글
String sf = m.request("sf");
String sk = m.request("sq");
clPost.addWhere("a.status = 1 AND a.course_id = " + courseId + " AND a.board_id = " + boardId + " AND e.status IN ( 1, 3 )");

if(!"".equals(sf)) clPost.addSearch(sf, sk, "LIKE");
else if("".equals(sf) && !"".equals(sk)) {
	Vector<String> v = new Vector<String>();
	v.add("a.subject LIKE '%" + f.get("sq") + "%'");
	v.add("a.content LIKE '%" + f.get("sq") + "%'");
	v.add("a.writer LIKE '%" + f.get("sq") + "%'");
	clPost.addWhere("(" + m.join(" OR ", v.toArray()) + ")");
}

DataSet prev = clPost.getPrevPost(info.i("board_id"), info.i("thread"), info.s("depth"));
DataSet next = clPost.getNextPost(info.i("board_id"), info.i("thread"), info.s("depth"));
if(prev.next()) { prev.put("reg_date_conv", m.time(_message.get("format.date.dot"), prev.s("reg_date"))); }
if(next.next()) { next.put("reg_date_conv", m.time(_message.get("format.date.dot"), next.s("reg_date"))); }

//출력
p.setLayout(ch);
p.setBody("classroom.review_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("prev", prev);
p.setVar("next", next);

p.setVar("active_epil", "select");
p.display();

%>