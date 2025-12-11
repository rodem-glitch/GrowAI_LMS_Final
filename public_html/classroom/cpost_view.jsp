<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
String code = m.rs("code");
if(id == 0 && "".equals(code)) { m.jsError(_message.get("alert.common.required_key")); return; }
boolean replyBlock = "free".equals(code) || ("Y".equals(SiteConfig.s("review_reply_yn")) && "review".equals(code));

//객체
ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
ClFileDao file = new ClFileDao();
KollusFileDao kollusFile = new KollusFileDao();

//정보-게시판
DataSet binfo = board.find("course_id = " + courseId + " AND code = '" + code + "' AND status = 1");
if(!binfo.next()) { m.jsError(_message.get("alert.board.nodata")); return; }
String btype = binfo.s("board_type");
int bid = binfo.i("id");
binfo.put("type_" + btype, true);

//정보
DataSet info = post.find("id = " + id + " AND display_yn = 'Y' AND status = 1");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//제한
if(info.b("secret_yn") && userId != info.i("user_id")) {
	m.jsError(_message.get("alert.post.private")); return;
}

//포맷팅
info.put("reg_date_conv", Malgn.time(_message.get("format.date.dot"), info.s("reg_date")));
info.put("mod_date_block", !"".equals(info.s("mod_date")));
info.put("mod_date_conv", Malgn.time(_message.get("format.date.dot"), info.s("mod_date")));
info.put("comment_conv", info.i("comm_cnt") > 0? "(" + info.i("comm_cnt") + ")" : "" );

info.put("hit_cnt_conv", m.nf(info.i("hit_cnt")));
info.put("subject_conv", Malgn.htt(info.s("subject")));
info.put("mod_block", info.i("user_id") == userId && info.i("proc_status") == 0);
info.put("writer_conv", "Y".equals(SiteConfig.s("masking_yn")) ? m.masking(info.s("writer")) : info.s("writer"));

if(!"".equals(info.s("upload_file_key"))) {
	info.put("content", info.s("content") + "<br/>" + kollusFile.getVideo(info.s("upload_file_key")));
}

//쿠키
String[] readArray = m.getCookie("CREAD").split("\\,");
if(!Malgn.inArray(""+id + "/" + userId, readArray)) {
	post.updateHitCount(id);
	String tmp = Malgn.join(",", readArray);
	tmp = "".equals(tmp) ? "" + id + "/" + userId : tmp + "," + id + "/" + userId;
	m.setCookie("CREAD", tmp, 3600 * 24);
}

//목록-파일
DataSet files = file.find("module = 'post' AND module_id = " + id + " AND status = 1");
while(files.next()) {
	files.put("ext", Malgn.replace(file.getFileIcon(files.s("filename")), "../html/images/admin/ext/unknown.gif", "/common/images/ext/unknown.gif"));
	files.put("ek", Malgn.encrypt(files.s("id")));
	files.put("filename", Malgn.htt(files.s("filename")));
	files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
}


//이전/다음글
String sf = m.request("s_field");
String sk = m.request("s_keywork");
post.appendWhere("a.status = 1");
post.appendWhere("a.course_id = " + courseId + "");
if("qna".equals(btype)) post.appendWhere("a.depth = 'A'");
if(!"".equals(sf)) post.addSearch(sf, sk, "LIKE");
else if("".equals(sf) && !"".equals(sk)) {
	Vector<String> v = new Vector<String>();
	v.add("a.subject LIKE '%" + f.get("sq") + "%'");
	v.add("a.content LIKE '%" + f.get("sq") + "%'");
	v.add("a.writer LIKE '%" + f.get("sq") + "%'");
	post.appendWhere("(" + Malgn.join(" OR ", v.toArray()) + ")");
}
DataSet prev = post.getPrevPost(info.i("board_id"), info.i("thread"), info.s("depth"));
DataSet next = post.getNextPost(info.i("board_id"), info.i("thread"), info.s("depth"));
if(prev.next()) { prev.put("reg_date_conv", Malgn.time(_message.get("format.date.dot"), prev.s("reg_date"))); }
if(next.next()) { next.put("reg_date_conv", Malgn.time(_message.get("format.date.dot"), next.s("reg_date"))); }


//답변
DataSet ainfo = new DataSet();
DataSet afiles = new DataSet();
if("qna".equals(btype)) {
	ainfo = post.find("thread = " + info.s("thread") + " AND depth = 'AA' AND display_yn = 'Y' AND status = 1", "*", "id DESC", 1);
	if(ainfo.next()) {
		ainfo.put("mod_date_conv", info.i("proc_status") == 1 ? Malgn.time(_message.get("format.date.dot"), ainfo.s("mod_date")) : "-");
		ainfo.put("content_conv", Malgn.htt(ainfo.s("content")));
		ainfo.put("proc_status_" + ainfo.s("proc_status"), true);
		ainfo.put("proc_status_conv", m.getValue(ainfo.s("proc_status"), post.procStatusListMsg));


		afiles = file.find("module = 'post' AND module_id = " + ainfo.i("id") + " AND status = 1");
		while(afiles.next()) {
			afiles.put("filename_conv", m.urlencode(Base64Coder.encode(afiles.s("filename"))));
			afiles.put("ext", file.getFileIcon(afiles.s("filename")));
			afiles.put("ek", Malgn.encrypt(afiles.s("id")));
		}
	} else {
		ainfo.addRow();
		ainfo.put("proc_status_0", true);
		ainfo.put("proc_status_conv", "미확인");
	}
}


//출력
p.setLayout(ch);
p.setBody("classroom.cview");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,pid"));
p.setVar("form_script", f.getScript());

p.setVar("board", binfo);
p.setVar(info);
p.setVar("prev", prev);
p.setVar("next", next);
p.setLoop("files", files);

p.setVar("answer", ainfo);
p.setVar("reply_block", replyBlock);
p.setLoop("afiles", afiles);

p.display();

%>