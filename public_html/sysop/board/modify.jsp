<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
MCal mcal = new MCal();

//정보
DataSet info = post.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 게시물이 없습니다."); return; }
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));
info.put("mod_date_block", !"".equals(info.s("mod_date")));
info.put("mod_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("mod_date")));

info.put("comment_conv", info.i("comm_cnt") > 0 ? "(" + info.i("comm_cnt") + ")" : "" );
info.put("hit_conv", m.nf(info.i("hit_cnt")));
//info.put("recomm_conv", m.nf(info.i("recomm_cnt")));
info.put("new_block", m.diffDate("H", info.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
info.put("notice_block", info.b("notice_yn"));
info.put("subject", m.htmlToText(info.s("subject")));

String categoryName = binfo.b("category_yn") ? category.getName(categories, info.s("category_id")) : "" ;
info.put("category_conv", !"".equals(categoryName) ? "[" + categoryName + "]" : "");

boolean isReplyPost = info.s("depth").length() > 1;
info.put("reply_block", isReplyPost);
info.put("content", m.htt(info.s("content")));

//폼체크
if(binfo.b("category_yn")) { f.addElement("category_id", info.s("category_id"), "hname:'카테고리', required:'Y'"); }
f.addElement("writer", info.s("writer"), "hname:'작성자', required:'Y'");
f.addElement("notice_yn", info.s("notice_yn"), "hname:'공지글 여부'");
f.addElement("secret_yn", info.s("secret_yn"), "hname:'비밀글 여부'");
f.addElement("subject", info.s("subject"), "hname:'제목', maxbyte:'250', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
f.addElement("reg_date", m.time("yyyy-MM-dd", info.s("reg_date")), "hname:'등록일', required:'Y'");
f.addElement("reg_hour", m.time("HH", info.s("reg_date")), "hname:'등록일(시)'");
f.addElement("reg_min", m.time("mm" ,info.s("reg_date")), "hname:'등록일(분)'");
f.addElement("hit_cnt", info.s("hit_cnt"), "hname:'조회수', required:'Y', option:'number'");
//f.addElement("recomm_cnt", info.s("recomm_cnt"), "hname:'추천수', required:'Y', option:'number'");
if("youtube".equals(btype)) f.addElement("youtube_cd", info.s("youtube_cd"), "hname:'유튜브링크'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부'");

//등록
if(m.isPost() && f.validate()) {

	String content = f.get("content1");
	//제한-이미지URI
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}

	//제한-용량
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(60000 < bytes) {
		m.jsAlert("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)");
		return;
	}

	//제한-비속어
	if(wordFilterDao.check(f.get("subject")) || wordFilterDao.check(content)) {
		m.jsAlert("비속어가 포함되어 수정할 수 없습니다.");
		return;
	}

	post.item("writer", f.get("writer"));
	post.item("category_id", !isReplyPost? f.get("category_id", "0") : info.s("category_id"));
	post.item("notice_yn", f.get("notice_yn", "N"));
	post.item("secret_yn", f.get("secret_yn", "N"));
	post.item("youtube_cd", f.get("youtube_cd"));

	post.item("subject", f.get("subject"));
	post.item("content", content);

	post.item("mod_date", m.time("yyyyMMddHHmmss"));
	post.item("hit_cnt", f.getInt("hit_cnt"));
	//post.item("recomm_cnt", f.getInt("recomm_cnt"));
	post.item("display_yn", f.get("display_yn"));

	post.item("reg_date", m.time("yyyyMMdd", f.get("reg_date")) + f.get("reg_hour") + f.get("reg_min") + "00");
	post.item("status", f.get("status", "1"));

	if(!post.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생하였습니다."); return; }

	mSession.put("file_module", "");
	mSession.put("file_module_id", 0);
	mSession.save();

	//이동
	m.jsReplace("index.jsp?" + m.qs(), "parent");
	return;
}

mSession.put("file_module", "post");
mSession.put("file_module_id", id);
mSession.save();

//출력
p.setLayout(ch);
p.setBody("board.write");
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());
p.setVar("list_query", m.qs("id"));

p.setVar("modify", true);
p.setVar(info);
p.setVar("board", binfo);
p.setVar("post_id", id);

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes());

p.setLoop("categories", categories);
p.setLoop("display_yn", m.arr2loop(post.displayYn));
p.display();

%>