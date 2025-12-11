<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//아이디
int pid = m.ri("pid");

//객체
MCal mcal = new MCal();

//정보-이전글
DataSet pinfo = new DataSet();
String subject = "";
//String content = "";
String permitId = "";
if(pid > 0) {
	pinfo = post.find("id = " + pid + "");
	if(!pinfo.next()) { m.jsError("이전 글 정보가 없습니다."); return; }
	pinfo.put("subject", "[RE] " + pinfo.s("subject"));
	pinfo.put("content", "<br><br><br><p style='margin:20px 0 10px 0'>[원문내용] " + m.repeatString("----", 20) + "</p>" + pinfo.s("content"));
}

//폼체크
if("Y".equals(binfo.s("category_yn"))) { f.addElement("category_id", null, "hname:'카테고리'"); }
f.addElement("writer", userName, "hname:'작성자', required:'Y'");
f.addElement("notice_yn", null, "hname:'공지글 여부'");
f.addElement("secret_yn", null, "hname:'비밀글 여부'");
f.addElement("subject", null, "hname:'제목', maxbyte:'250', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
if("youtube".equals(btype)) f.addElement("youtube_cd", null, "hname:'유튜브링크'");
f.addElement("reg_date", m.time("yyyy-MM-dd"), "hname:'등록일', required:'Y'");
f.addElement("reg_hour", m.time("HH"), "hname:'등록일(시)'");
f.addElement("reg_min", m.time("mm"), "hname:'등록일(분)'");
f.addElement("display_yn", "Y", "hname:'노출여부'");

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
		m.jsAlert("비속어가 포함되어 등록할 수 없습니다.");
		return;
	}

	int newId = post.getSequence();

	post.item("id", newId);
	post.item("site_id", siteId);
	post.item("board_id", bid);
	post.item("category_id", pid  == 0? f.get("category_id", "0") : pinfo.s("category_id"));
	post.item("thread", pid == 0 ? post.getLastThread() : pinfo.i("thread"));
	post.item("depth", pid == 0 ? "A" : post.getThreadDepth(pinfo.i("thread"), pinfo.s("depth")));
	post.item("user_id", userId);
	post.item("writer", f.get("writer"));
	post.item("subject", f.get("subject"));
	post.item("content", content);
	post.item("notice_yn", f.get("notice_yn", "N"));
	post.item("secret_yn", f.get("secret_yn", "N"));
	post.item("youtube_cd", f.get("youtube_cd"));
	post.item("display_yn", f.get("display_yn"));

	post.item("reg_date", m.time("yyyyMMdd", f.get("reg_date")) + f.get("reg_hour") + f.get("reg_min") + "00");
	post.item("status", f.get("status", "1"));

	if(!post.insert()) { m.jsAlert("등록하는 중 오류가 발생하였습니다."); return; }

	//임시로 올려진 파일들의 게시물 아이디 지정
	file.updateTempFile(f.getInt("temp_id"), newId, "post");

	//갱신
	post.updateFileCount(newId);

	mSession.put("file_module", "");
	mSession.put("file_module_id", 0);
	mSession.save();

	//이동
	m.jsReplace("index.jsp?" + m.qs(), "parent");
	return;
}

int tempId = m.getRandInt(-2000000, 1990000);

mSession.put("file_module", "post");
mSession.put("file_module_id", tempId);
mSession.save();

//출력
p.setLayout(ch);
p.setBody("board.write");
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("board", binfo);
p.setVar(pinfo);
p.setVar("reply_block", pid > 0);

p.setLoop("hours", mcal.getHours());
p.setLoop("minutes", mcal.getMinutes());

p.setVar("post_id", tempId);
p.setLoop("categories", categories);
p.setLoop("display_yn", m.arr2loop(post.displayYn));
p.display();

%>