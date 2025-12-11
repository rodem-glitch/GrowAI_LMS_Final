<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int qid = m.ri("qid");
if(qid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
ClFileDao clFile = new ClFileDao();

//정보
DataSet info = clPost.query(
	"SELECT a.*, b.board_nm, b.board_type, u.login_id "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.code = 'qna' AND b.status = 1 "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1 "
	+ " LEFT JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
	+ " WHERE a.status != -1 AND a.id = " + qid + " AND a.user_id = " + uid + " "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("hit_cnt_conv", m.nf(info.getInt("hit_cnt")));

//목록-파일
DataSet files = clFile.find("module = 'post' AND module_id = " + qid + "");
while(files.next()) {
	files.put("file_ext", clFile.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(m.encode(files.s("filename"))));
	files.put("ext", clFile.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id")));
}

//답변
DataSet ainfo = clPost.find("thread = " + info.s("thread") + " AND depth = 'AA' AND status = 1", "*", "id DESC", 1);
if(!ainfo.next()) {
	int newId = clPost.getSequence();

	clPost.item("id", newId);
	clPost.item("site_id", siteId);
	clPost.item("course_id", info.i("course_id"));
	clPost.item("board_id", info.i("board_id"));
	clPost.item("course_user_id", info.i("course_user_id"));
	clPost.item("thread", info.i("thread"));
	clPost.item("depth", "AA");
	clPost.item("user_id", userId);
	clPost.item("writer", userName);
	clPost.item("subject", info.s("subject"));
	clPost.item("content", "");
	clPost.item("notice_yn", "N");

	clPost.item("mod_date", m.time("yyyyMMddHHmmss"));
	clPost.item("reg_date", m.time("yyyyMMddHHmmss"));
	clPost.item("proc_status", 0);
	clPost.item("status",1);

	if(!clPost.insert()) { m.jsAlert("등록하는 중 오류가 발생하였습니다."); return; }

	ainfo = clPost.find("id = " + newId + "");
	ainfo.next();
}
ainfo.put("mod_date_conv", info.i("proc_status") == 1 ? m.time("yyyy.MM.dd", ainfo.s("mod_date")) : "-");
ainfo.put("content_conv", m.htt(ainfo.s("content")));
ainfo.put("proc_status_" + ainfo.s("proc_status"), true);
ainfo.put("proc_status_conv", m.getItem(ainfo.s("proc_status"), clPost.procStatusList));

DataSet afiles = clFile.find("module = 'post' AND module_id = " + ainfo.i("id") + " AND status = 1");
while(afiles.next()) {
	afiles.put("filename_conv", m.urlencode(Base64Coder.encode(afiles.s("filename"))));
	afiles.put("ext", clFile.getFileIcon(afiles.s("filename")));
	afiles.put("ek", m.encrypt(afiles.s("id")));
}



//출력
p.setLayout(ch);
p.setBody("crm.cqna_view");
p.setVar("list_query", m.qs("qid"));

p.setVar(info);
p.setLoop("files", files);
p.setVar("answer", ainfo);
p.setLoop("afiles", afiles);

p.setVar("tab_qna", "current");
p.setVar("tab_sub_cqna", "current");
p.display();

%>