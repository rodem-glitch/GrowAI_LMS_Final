<%@ page contentType="text/html; charset=utf-8" %><%@ include file="post_init.jsp" %><%

//게시판권한
if(!board.accessible("list", bid, userGroups, userKind) && !isBoardAdmin) { m.jsError(_message.get("alert.common.permission_list")); return; }

//폼체크
f.addElement("s_category", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("ord", null, null);

//객체
UserDao user = new UserDao();

//목록
ListManager lm = new ListManager(jndi);
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setNaviNum(5);
lm.setTable(
	post.table + " a "
	+ " LEFT JOIN " + file.table + " f ON f.module = 'post' AND f.module_id = a.id AND f.main_yn = 'Y' "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
);
lm.setFields("a.*, c.category_nm, f.filename, u.login_id");
lm.addWhere("a.display_yn = 'Y'");
lm.addWhere("a.status = 1");
lm.addWhere("a.board_id = " + bid);
if(binfo.b("private_yn")) lm.addWhere("a.user_id = " + userId);
if("qna".equals(btype)) lm.addWhere("a.depth = 'A'");
lm.addSearch("a.category_id", f.get("s_category"));

String sField = f.get("s_field", "");
String allowFields = "a.subject,a.content,a.writer";
if(!m.inArray(sField, allowFields)) sField = "";
if(!"".equals(sField)) lm.addSearch(sField, f.get("s_keyword"), "LIKE");
else lm.addSearch(allowFields, f.get("s_keyword"), "LIKE");

lm.setOrderBy(!"".equals(f.get("ord")) ? f.get("ord") : ("faq".equals(btype) ? "a.sort ASC, " : "") + "a.thread ASC, a.depth ASC");

//포맷팅
//int no = 1;
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", m.time(_message.get("format.date.dot"), list.s("reg_date")));
	list.put("mod_date_conv", m.time(_message.get("format.date.dot"), list.s("mod_date")));

	list.put("content_conv", m.stripTags(list.s("content")));
	list.put("comment_conv", binfo.b("comment_yn") && list.i("comm_cnt") > 0 ? "(" + list.i("comm_cnt") + ")" : "" );
	list.put("file_block", list.i("file_cnt") > 0);
	list.put("hit_cnt_conv", m.nf(list.i("hit_cnt")));
	list.put("new_block", m.diffDate("H", list.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
	list.put("category_conv", binfo.b("category_yn") && !"".equals(list.s("category_nm")) ? "[" + list.s("category_nm") + "]" : "");
	list.put("subject_conv", m.cutString(list.s("subject"), 60));
	list.put("reply_block", list.s("depth").length() > 1);
	list.put("secret_block", list.b("secret_yn") && userId != list.i("user_id"));
	list.put("proc_status_class_conv", list.b("proc_status") ? "label_complete" : "label_ing");
	list.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(list.s("writer")) : list.s("writer"));

	//타입별 처리
	if("board".equals(btype)) {	//리스트형
		//답글
		int replyWidth = (list.s("depth").length() - 1) * 15;
		list.put("reply_width", replyWidth > 200 ? 200 : replyWidth);
	} else if("qna".equals(btype)) {	//QNA
		list.put("proc_status_conv", m.getItem(list.s("proc_status"), post.procStatusList));
	} else if("faq".equals(btype)) {	//FAQ
		//목록-파일
		DataSet files = file.getFileList(list.i("id"), "post");
		while(files.next()) {
			files.put("file_ext", file.getFileExt(files.s("filename")));
			files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
			files.put("ext", file.getFileIcon(files.s("filename")));
			files.put("ek", m.encrypt(files.s("id") + m.time("yyyyMMdd")));
			files.put("sep", !files.b("__last") ? "<br>" : "");
		}
		list.put(".files", files);
	}
	
	//이미지
	if(!"".equals(list.s("filename"))) {
		list.put("file_url", m.getUploadUrl(list.s("filename")));
	} else {
		list.put("file_url", "/common/images/default/noimage_gallery.jpg");
	}
}

//공지사항/베스트/상위
DataSet notices = new DataSet();
if(binfo.b("notice_yn")) {
	notices = post.query(
		"SELECT a.*, f.filename, u.login_id "
		+ " FROM " + post.table + " a "
		+ " LEFT JOIN " + file.table + " f ON f.module = 'post' AND f.module_id = a.id AND f.main_yn = 'Y' "
		+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
		+ " WHERE a.status = 1 AND a.board_id = " + bid + " "
		+ " AND a.notice_yn = 'Y' "
		+ " ORDER BY a.thread ASC, a.depth ASC "
	);
	while(notices.next()) {
		notices.put("content_conv", m.stripTags(notices.s("content")));
		notices.put("reg_date_conv", m.time(_message.get("format.date.dot"), notices.s("reg_date")));
		notices.put("mod_date_conv", m.time(_message.get("format.date.dot"), notices.s("mod_date")));
		notices.put("comment_conv", binfo.b("comment_yn") && notices.i("comm_cnt") > 0 ? "(" + notices.i("comm_cnt") + ")" : "" );
		notices.put("file_block", notices.i("file_cnt") > 0);
		notices.put("hit_cnt_conv", m.nf(notices.i("hit_cnt")));
		notices.put("new_block", m.diffDate("H", notices.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
		notices.put("category_conv", binfo.b("category_yn") && !"".equals(notices.s("category_nm")) ? "[" + notices.s("category_nm") + "]" : "");
		notices.put("subject_conv", m.cutString(notices.s("subject"), 30));
		notices.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(notices.s("writer")) : notices.s("writer"));

		//이미지
		if(!"".equals(notices.s("filename"))) {
			notices.put("file_url", m.getUploadUrl(notices.s("filename")));
		} else {
			notices.put("file_url", "/common/images/default/noimage_gallery.jpg");
		}
	}
}

//탬플릿
String body = "list";
if("faq".equals(btype)) body = "faq";
else if("qna".equals(btype)) body = "qna";
else if("youtube".equals(btype)) body = "youtube";
else if("gallery".equals(btype)) body = "gallery";
else if("webzine".equals(btype)) body = "webzine";

//출력
p.setLayout(ch);
p.setBody("mobile.post_" + body);
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar("board", binfo);
p.setLoop("categories", categories);
p.setLoop("notices", notices);

p.setVar("board_write_block", board.accessible("write", bid, userGroups, userKind));
p.display();

%>