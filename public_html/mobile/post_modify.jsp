<%@ page contentType="text/html; charset=utf-8" %><%@ include file="post_init.jsp" %><%

//로그인
if(userId == 0) { m.redirect("login.jsp"); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//정보
DataSet info = post.find("id = " + id + " AND site_id = " + siteId + " AND display_yn = 'Y' AND status = 1");
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

//제한
if(info.i("user_id") != userId && !isBoardAdmin) { m.jsError(_message.get("alert.common.permission_modify")); return; }
//info.put("content", m.htmlentities(info.s("content")));

//파일
DataSet finfo = file.getFileList(id, "post");

//폼체크
if(binfo.b("category_yn")) { f.addElement("category_id", info.s("category_id"), "hname:'카테고리', required:'Y'"); }
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("notice_yn", info.s("notice_yn"), "hname:'공지글 여부'");
f.addElement("secret_yn", info.s("secret_yn"), "hname:'비밀글 여부'");
f.addElement("content", info.s("content"), "hname:'내용'");
f.addElement("keyword", info.s("keyword"), "hname:'키워드'");
if("youtube".equals(btype)) f.addElement("youtube_cd", info.s("youtube_cd"), "hname:'유튜브링크'");

//등록
if(m.isPost() && f.validate()) {

	if(!"".equals(f.get("icode_captcha")) && !f.get("icode").equals(f.get("icode_captcha"))) {
		m.jsAlert(_message.get("alert.common.captcha"));
		return;
	}

	String content = m.htmlToText(f.get("content"));

	//제한-용량
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert(_message.get("alert.board.over_capacity", new String[] {"maximum=>60000", "bytes=>" + bytes}));
		return;
	}

	post.item("writer", userName);
	post.item("category_id", f.getInt("category_id"));
	post.item("notice_yn", f.get("notice_yn", "N"));
	post.item("secret_yn", f.get("secret_yn", "N"));
	post.item("subject", f.get("subject"));
	post.item("youtube_cd", f.get("youtube_cd"));
	post.item("content", f.get("content"));

	if(!post.update("id = " + id + "")) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	//갱신-파일갯수
	post.updateFileCount(id);

	mSession.put("file_module", "");
	mSession.put("file_module_id", 0);
	mSession.save();

	//이동
	m.jsReplace("post_view.jsp?" + m.qs("pid"), "parent");
	return;
}

//포맷팅
if(finfo.next()) {
	finfo.put("file_ext", file.getFileExt(finfo.s("filename")));
	finfo.put("filename_conv", m.urlencode(Base64Coder.encode(finfo.s("filename"))));
	finfo.put("ext", file.getFileIcon(finfo.s("filename")));
	finfo.put("ek", m.encrypt(finfo.s("id") + m.time("yyyyMMdd")));
}

mSession.put("file_module", "post");
mSession.put("file_module_id", id);
mSession.save();

//출력
p.setLayout(ch);
p.setBody("mobile.post_insert");
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,pid"));
p.setVar("form_script", f.getScript());

p.setVar("board", binfo);
p.setVar(info);
p.setVar("modify", true);
p.setVar("post_id", id);
p.setVar("file", finfo);

p.setLoop("categories", categories);
p.display();

%>