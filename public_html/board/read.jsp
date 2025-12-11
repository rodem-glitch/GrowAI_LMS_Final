<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//게시판권한
if(!board.accessible("read", bid, userGroups, userKind) && !isBoardAdmin) { 
	if(userId == 0) {
		m.jsAlert(_message.get("alert.member.required_login"));
		m.jsReplace("/member/login.jsp?returl=/board/read.jsp?" + m.qs());
	} else {
		m.jsError(_message.get("alert.common.permission_view"));
	}
	return;
}

//기본키
int id = m.ri("id");
String ek = m.rs("ek");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
CommentDao comment = new CommentDao();

//정보
DataSet info = post.query(
	" SELECT a.*, u.login_id "
	+ " FROM " + post.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.id = ? AND a.display_yn = 'Y' AND a.status = 1 AND a.site_id = " + siteId + ""
	+ (binfo.b("private_yn") ? " AND a.user_id = " + userId : "")
	+ ("qna".equals(btype) ? " AND a.depth = 'A' " : "")
	, new Object[] { id }
);
if(!info.next()) { m.jsError(_message.get("alert.post.nodata")); return; }

//제한
if(info.b("secret_yn") && userId != info.i("user_id")) {
	m.jsError(_message.get("alert.post.private")); return;
}

//포맷팅
info.put("subject_htt", Malgn.htt(info.s("subject")));
info.put("reg_date_conv", Malgn.time(_message.get("format.date.dot"), info.s("reg_date")));
info.put("mod_date_block", !"".equals(info.s("mod_date")));
info.put("mod_date_conv", Malgn.time(_message.get("format.date.dot"), info.s("mod_date")));
info.put("comment_conv", info.i("comm_cnt") > 0? "(" + info.i("comm_cnt") + ")" : "" );
info.put("file_block", info.i("file_cnt") > 0);

info.put("hit_cnt_conv", Malgn.nf(info.i("hit_cnt")));
info.put("recomm_cnt_conv", Malgn.nf(info.i("recomm_cnt")));
info.put("new_block", Malgn.diffDate("H", info.s("reg_date"), sysNow) <= newHour);
info.put("subject", Malgn.htt(info.s("subject")));

info.put("content", info.s("content").replaceAll(" on([^\\t\\n\\f\\- \\/>\"'=]+\\s*)=", " on-$1="));
info.put("content", info.s("content").replaceAll("&", "&amp;").replaceAll("\"", "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll("'", "&#39;").replaceAll("/", "&#x2F;").replaceAll("\\(", "&#40;").replaceAll("\\)", "&#41;"));
info.put("content", info.s("content").replaceAll(allowRegexr, "&lt;$1$2&gt;"));
info.put("content_conv", Malgn.htt(info.s("content")));

info.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(info.s("writer")) : info.s("writer"));

String categoryName = binfo.b("category_yn") ? category.getName(categories, info.s("category_id")) : "" ;
info.put("category_conv", !"".equals(categoryName) ? "[" + categoryName + "]" : "");

//업데이트-조회수//쿠키셋팅
String[] readArray = null;
readArray = m.getCookie("READ").split("\\,");
if(!Malgn.inArray("" + id, readArray)) {
	post.updateHitCount(id);
	String tmp = Malgn.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id : tmp + "," + id;
	m.setCookie("READ", tmp, 3600 * 24);
}

//로그등록-읽기
//PostLogDao postLog = new PostLogDao();
//if(!"".equals(userId)) postLog.log(userId, id, "read");

//목록-파일
DataSet files = file.getFileList(id, "post", binfo.b("image_yn"));
while(files.next()) {
	files.put("file_ext", file.getFileExt(files.s("filename")));
	files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
	files.put("filename", Malgn.htt(files.s("filename")));
	files.put("ext", file.getFileIcon(files.s("filename")));
	files.put("ek", Malgn.encrypt(files.s("id") + sysToday));
	files.put("sep", !files.b("__last") ? "<br>" : "");
}

//이전글/다음글
DataSet pinfo = new DataSet();
DataSet ninfo = new DataSet();
post.appendSearch("a.category_id", m.rs("s_category_id"));
if(!"".equals(f.get("s_field")) && Malgn.inArray(f.get("s_field"),"a.subject,a.content,a.writer")) {
	post.appendSearch(m.rs("s_field"), m.rs("s_keyword"), "LIKE");
} else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	Vector<String> v = new Vector<String>();
	v.add("a.subject LIKE '%" + m.rs("s_keyword") + "%'");
	v.add("a.content LIKE '%" + m.rs("s_keyword") + "%'");
	v.add("a.writer LIKE '%" + m.rs("s_keyword") + "%'");
	post.appendWhere("(" + Malgn.join(" OR ", v.toArray()) + ")");
}
pinfo = post.getPrevPost(bid, info.i("thread"), info.s("depth"));
ninfo = post.getNextPost(bid, info.i("thread"), info.s("depth"));
if(pinfo.next()) {
	pinfo.put("reg_date_conv", Malgn.time(_message.get("format.date.dot"), pinfo.s("reg_date")));
	pinfo.put("comment_conv", pinfo.i("comm_cnt") > 0? "(" + pinfo.i("comm_cnt") + ")" : "" );
	pinfo.put("file_block", pinfo.i("file_cnt") > 0);
	pinfo.put("hit_cnt_conv", Malgn.nf(pinfo.i("hit_cnt")));
	pinfo.put("recomm_cnt_conv", Malgn.nf(pinfo.i("recomm_cnt")));
	pinfo.put("new_block", Malgn.diffDate("H", pinfo.s("reg_date"), sysNow) <= newHour);
	pinfo.put("subject_conv", Malgn.cutString(pinfo.s("subject"), 80));

	categoryName = binfo.b("category_yn") ? category.getName(categories, pinfo.s("category_id")) : "" ;
	pinfo.put("category_conv", !"".equals(categoryName) ? "[" + categoryName + "]" : "");
}
if(ninfo.next()) {
	ninfo.put("reg_date_conv", Malgn.time(_message.get("format.date.dot"), ninfo.s("reg_date")));
	ninfo.put("comment_conv", ninfo.i("comm_cnt") > 0? "(" + ninfo.i("comm_cnt") + ")" : "" );
	ninfo.put("file_block", ninfo.i("file_cnt") > 0);
	ninfo.put("hit_cnt_conv", Malgn.nf(ninfo.i("hit_cnt")));
	ninfo.put("recomm_cnt_conv", Malgn.nf(ninfo.i("recomm_cnt")));
	ninfo.put("new_block", Malgn.diffDate("H", ninfo.s("reg_date"), sysNow) <= newHour);
	ninfo.put("subject_conv", Malgn.cutString(ninfo.s("subject"), 80));

	categoryName = binfo.b("category_yn") ? category.getName(categories, ninfo.s("category_id")) : "" ;
	ninfo.put("category_conv", !"".equals(categoryName) ? "[" + categoryName + "]" : "");
}

//답변
DataSet ainfo = new DataSet();
DataSet afiles = new DataSet();
if("qna".equals(btype)) {
	ainfo = post.query(
		" SELECT a.*, u.login_id "
		+ " FROM " + post.table + " a "
		+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
		+ " WHERE a.thread = " + info.s("thread") + " AND a.depth = 'AA' AND a.display_yn = 'Y' AND a.status = 1"
		+ " ORDER BY a.id DESC "
		+ " LIMIT 1 "
	);
	if(ainfo.next()) {
		ainfo.put("mod_date_conv", info.i("proc_status") == 1 ? Malgn.time(_message.get("format.date.dot"), ainfo.s("mod_date")) : "-");
		ainfo.put("content_conv", Malgn.htt(ainfo.s("content")));
		ainfo.put("answer_block", ainfo.i("proc_status") == 1);
		ainfo.put("proc_status_conv", m.getValue(ainfo.s("proc_status"), post.procStatusListMsg));
		ainfo.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(ainfo.s("writer")) : ainfo.s("writer"));

		afiles = file.getFileList(ainfo.i("id"), "post", binfo.b("image_yn"));
		while(afiles.next()) {
			afiles.put("file_ext", file.getFileExt(afiles.s("filename")));
			afiles.put("filename_conv", m.urlencode(Base64Coder.encode(afiles.s("filename"))));
			afiles.put("ext", file.getFileIcon(afiles.s("filename")));
			afiles.put("ek", Malgn.encrypt(afiles.s("id") + sysToday));
			afiles.put("sep", !afiles.b("__last") ? "<br>" : "");
		}
	} else {
		ainfo.addRow();
		ainfo.put("proc_status_conv", "답변대기");
	}
}

//출력
p.setLayout(ch);
p.setBody("board.read");
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,ek"));
p.setVar("form_script", f.getScript());

p.setVar("board", binfo);
p.setVar(info);
p.setLoop("categories", categories);
p.setLoop("files", files);
p.setVar("file_block", files.size() > 0);

p.setVar("prev", pinfo);
p.setVar("next", ninfo);
p.setVar("answer", ainfo);
p.setLoop("afiles", afiles);
p.setVar("board_modify_block", ((info.i("user_id") != 0 && info.i("user_id") == userId) || isBoardAdmin) && info.i("proc_status") == 0);
p.setVar("board_delete_block", binfo.b("delete_yn") || (!binfo.b("delete_yn") && 1 > comment.findCount("module = 'post' AND module_id = " + id + " AND status = 1")));
p.display();

%>