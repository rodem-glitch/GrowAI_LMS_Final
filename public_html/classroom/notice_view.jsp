<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
ClFileDao clFile = new ClFileDao();

//정보
DataSet info = clPost.query(
	"SELECT a.*"
	+ " FROM " + clPost.table + " a"
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id"
	+ " WHERE a.display_yn = 'Y' AND a.status = 1 AND b.board_type = 1 "
	+ " AND a.id = " + id + " AND a.course_id = " + courseId + ""
);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
info.put("reg_date_conv", m.time(_message.get("format.date.dot"), info.s("reg_date")));

//파일정보
DataSet files = clFile.query(
	"SELECT a.* "
	+ " FROM " + clFile.table + " a "
	+ " WHERE module = 'post' AND module_id = " + id + " "
	+ " ORDER BY a.id ASC"
);
while(files.next()) {
	files.put("ext", m.replace(clFile.getFileIcon(files.s("filename")), "../html/images/admin/ext/unknown.gif", "/common/images/ext/unknown.gif"));
	files.put("ek", m.encrypt(files.s("id")));
	files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
}

//업데이트-조회수//쿠키셋팅
String[] readArray = m.getCookie("CREAD").split("\\,");
if(!m.inArray("" + id, readArray)) {
	clPost.execute("UPDATE " + clPost.table + " SET hit_cnt = hit_cnt + 1 WHERE id = " + id);
	String tmp = m.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id : tmp + "," + id;
	m.setCookie("CREAD", tmp, 3600 * 24);
}

//이전/다음글
String sf = m.rs("sf");
String sk = m.rs("sq");
clPost.addWhere("a.status = 1");
clPost.addWhere("b.board_type = 1");
clPost.addWhere("a.course_id = " + courseId + "");
if(!"".equals(sf)) clPost.addSearch(sf, sk, "LIKE");
else if("".equals(sf) && !"".equals(sk)) {
	Vector<String> v = new Vector<String>();
	v.add("a.subject LIKE '%" + f.get("sq") + "%'");
	v.add("a.content LIKE '%" + f.get("sq") + "%'");
	clPost.addWhere("(" + m.join(" OR ", v.toArray()) + ")");
}

DataSet prev = clPost.getPrevPost(info.i("board_id"), info.i("thread"), info.s("depth"));
DataSet next = clPost.getNextPost(info.i("board_id"), info.i("thread"), info.s("depth"));
if(prev.next()) { prev.put("reg_date_conv", m.time(_message.get("format.date.dot"), prev.s("reg_date"))); }
if(next.next()) { next.put("reg_date_conv", m.time(_message.get("format.date.dot"), next.s("reg_date"))); }

//출력
p.setLayout(ch);
p.setBody("classroom.notice_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("prev", prev);
p.setVar("next", next);
p.setLoop("files", files);

p.setVar("active_notice", "select");
p.display();

%>