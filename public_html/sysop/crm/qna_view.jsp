<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int qid = m.ri("qid");
if(qid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
BoardDao board = new BoardDao();
PostDao post = new PostDao();
FileDao file = new FileDao();

//정보
DataSet info = post.query(
	"SELECT a.*, b.board_nm, b.board_type, u.login_id "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.board_type = 'qna' AND b.status = 1 "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1 "
	+ " WHERE a.status != -1 AND a.id = ? AND a.user_id = ? "
	, new Object[] { qid, uid }
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= 24);
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("hit_cnt_conv", m.nf(info.getInt("hit_cnt")));

//목록-파일
DataSet files = file.find("module = 'post' AND module_id = ?", new Object[] { qid });
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(m.encode(files.s("filename"))));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", m.encrypt(files.s("id")));
}

//답변
DataSet ainfo = post.find("thread = " + info.s("thread") + " AND depth = 'AA' AND status != -1", "*", "id DESC", 1);
if(!ainfo.next()) {
	int newId = post.getSequence();

	post.item("id", newId);
	post.item("site_id", siteId);
	post.item("board_id", info.i("board_id"));
	post.item("category_id", info.s("category_id"));
	post.item("thread", info.i("thread"));
	post.item("depth", "AA");
	post.item("user_id", userId);
	post.item("writer", userName);
	post.item("subject", info.s("subject"));
	post.item("content", "");
	post.item("notice_yn", "N");

	post.item("reg_date", m.time("yyyyMMddHHmmss"));
	post.item("proc_status", 0);
	post.item("status", 1);

	if(!post.insert()) { m.jsAlert("등록하는 중 오류가 발생하였습니다."); return; }

	ainfo = post.find("id = " + newId + "");
	ainfo.next();
}
ainfo.put("mod_date_conv", info.i("proc_status") == 1 ? m.time("yyyy.MM.dd HH:mm", ainfo.s("mod_date")) : "-");
ainfo.put("content_conv", m.htt(ainfo.s("content")));
ainfo.put("proc_status_" + ainfo.s("proc_status"), true);
ainfo.put("proc_status_conv", m.getItem(ainfo.s("proc_status"), post.procStatusList));

DataSet afiles = file.find("module = 'post' AND module_id = " + ainfo.i("id") + " AND status = 1");
while(afiles.next()) {
	afiles.put("filename_conv", m.urlencode(Base64Coder.encode(afiles.s("filename"))));
	afiles.put("ext", file.getFileIcon(afiles.s("filename")));
	afiles.put("ek", m.encrypt(afiles.s("id")));
}

//출력
p.setLayout(ch);
p.setBody("crm.qna_view");
p.setVar("list_query", m.qs("qid"));

p.setVar(info);
p.setLoop("files", files);
p.setVar("answer", ainfo);
p.setLoop("afiles", afiles);

p.setVar("tab_qna", "current");
p.setVar("tab_sub_qna", "current");
p.display();

%>