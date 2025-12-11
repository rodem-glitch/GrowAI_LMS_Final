<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
String code = m.rs("code");
if(id == 0 && "".equals(code)) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
ClFileDao file = new ClFileDao();
KollusFileDao kollusFile = new KollusFileDao();
WordFilterDao wordFilterDao = new WordFilterDao();

//정보-게시판
DataSet binfo = board.find("course_id = " + courseId + " AND code = '" + code + "' AND status = 1");
if(!binfo.next()) { m.jsError(_message.get("alert.board.nodata")); return; }
String btype = binfo.s("board_type");
int bid = binfo.i("id");
binfo.put("type_" + btype, true);

//정보
DataSet info = post.find("id = " + id + " AND display_yn = 'Y' AND status = 1");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }
info.put("content", info.s("content") + kollusFile.getVideo(info.s("upload_file_key")));
info.put("content", m.htt(info.s("content")));

//제한
if(userId != info.i("user_id")) { m.jsError(_message.get("alert.common.permission_modify")); return; }


//목록-파일
DataSet files = file.find("module = 'post' AND module_id = " + id + " AND status = 1");
while(files.next()) {
	files.put("ext", m.replace(file.getFileIcon(files.s("filename")), "../html/images/admin/ext/unknown.gif", "/common/images/ext/unknown.gif"));
	files.put("ek", m.encrypt(files.s("id")));
	files.put("filename_conv", m.urlencode(Base64Coder.encode(files.s("filename"))));
}

//폼체크
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("secret_yn", info.s("secret_yn"), "hname:'비밀글 여부'");
f.addElement("content", null, "hname:'내용',allowhtml:'Y'");
if("recomm".equals(btype)) f.addElement("point", info.i("point"), "hname:'점수', required:'Y'");
if("qna".equals(btype)) f.addElement("upload_file_key", info.s("upload_file_key"), "hname:'콜러스영상'");

//등록
if(m.isPost() && f.validate()) {

	String content = f.get("content");
	//제한-이미지URI
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert(_message.get("alert.board.attach_image"));
		return;
	}

	//제한-용량
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert(_message.get("alert.board.over_capacity", new String[] {"maximum=>60000", "bytes=>" + bytes}));
		return;
	}

	//제한-비속어
	if(wordFilterDao.check(f.get("subject")) || wordFilterDao.check(content)) {
		m.jsAlert("비속어가 포함되어 수정할 수 없습니다.");
		return;
	}

	post.item("notice_yn", f.get("notice_yn", "N"));
	post.item("secret_yn", f.get("secret_yn", "N"));
	post.item("subject", f.get("subject"));
	post.item("content", content);
	post.item("point", f.getInt("point"));
	post.item("upload_file_key", f.get("upload_file_key"));
	if(!post.update("id = " + id + "")) { m.jsAlert(_message.get("alert.common.error_modify")); return; }

	if("qna".equals(btype)) {
		File f1 = f.saveFile("question_file");
		if(f1 != null) {
			files.first();
			if(files.next()) {
				if(!"".equals(files.s("filename"))) m.delFileRoot(m.getUploadPath(files.s("filename")));
				file.item("status", -1);
				if(!file.update("module = 'post' AND module_id = " + id)) { }
			}

			file.item("site_id", siteId);
			file.item("module", "post");
			file.item("module_id", id);
			file.item("filename", f.getFileName("question_file"));
			file.item("filetype", f.getFileType("question_file"));
			file.item("filesize", f1.length());
			file.item("realname", f1.getName());
			file.item("main_yn", "N");
			file.item("reg_date", m.time("yyyyMMddHHmmss"));
			file.item("status", 1);
			file.insert();
		}
	}

	//갱신
	post.updateFileCount(id);

	//이동
	m.jsReplace("cpost_list.jsp?" + m.qs("id"), "parent");
	return;
}


//포맷팅
info.put("reg_date_conv", m.time(_message.get("format.date.dot"), info.s("reg_date")));
info.put("mod_date_block", !"".equals(info.s("mod_date")));
info.put("mod_date_conv", m.time(_message.get("format.date.dot"), info.s("mod_date")));
info.put("comment_conv", info.i("comm_cnt") > 0? "(" + info.i("comm_cnt") + ")" : "" );

info.put("hit_cnt_conv", m.nf(info.i("hit_cnt")));
info.put("subject_conv", m.htt(info.s("subject")));
info.put("mod_block", info.i("user_id") == userId && info.i("proc_status") == 0);

//출력
p.setLayout(ch);
p.setBody("classroom.cwrite");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,pid"));
p.setVar("form_script", f.getScript());

p.setVar("board", binfo);
p.setVar(info);
p.setVar("post_id", id);
p.setLoop("files", files);

p.setVar("modify", true);
p.setVar("active_" + code, "select");
p.setVar("kollus_upload_block", !"".equals(SiteConfig.s("kollus_clpost_key")));

p.display();

%>