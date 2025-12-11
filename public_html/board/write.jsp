<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//로그인
if(userId == 0) { auth.loginForm(); return; }

//아이디
int pid = m.ri("pid");

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"ktalk_"});

//객체
MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
KtalkDao ktalk = new KtalkDao(siteId);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId);
WordFilterDao wordFilterDao = new WordFilterDao();

//정보-이전글
DataSet pinfo = new DataSet();
String subject = "";
//String content = "";
String permitId = "";
if(pid > 0) {
	//게시판권한
	if(!board.accessible("reply", bid, userGroups, userKind) && !isBoardAdmin) { m.jsError(_message.get("alert.common.permission_reply")); return; }

	//정보
	pinfo = post.find("id = " + pid + " AND display_yn = 'Y' AND status = 1");
	if(!pinfo.next()) { m.jsError(_message.get("alert.post.nodata_parent"));	return;  }
	pinfo.put("subject", "[RE] " + pinfo.s("subject"));
	pinfo.put("content", "<br><br><br><p style='margin:20px 0 10px 0'>[원문내용] " + m.repeatString("----", 20) + "</p>" + pinfo.s("content"));
} else {
	//게시판권한
	if(!board.accessible("write", bid, userGroups, userKind) && !isBoardAdmin) { m.jsError(_message.get("alert.common.permission_insert")); return; }
	pinfo.put("content", m.htt(pinfo.s("content")));
}

//폼체크
if(binfo.b("category_yn")) { f.addElement("category_id", null, "hname:'카테고리', required:'Y'"); }
f.addElement("subject", pid > 0 ? pinfo.s("subject") : "" , "hname:'제목', maxbyte:'250', required:'Y'");
f.addElement("notice_yn", null, "hname:'공지글 여부'");
f.addElement("secret_yn", "qna".equals(btype) ? "Y" : "N", "hname:'비밀글 여부'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
f.addElement("keyword", null, "hname:'키워드'");
if("youtube".equals(btype)) f.addElement("youtube_cd", null, "hname:'유튜브링크'");

//등록
if(m.isPost() && f.validate()) {

	//제한-글작성수
	if(2 < post.findCount("site_id = " + siteId + " AND user_id = " + userId + " AND reg_date >= '" + m.addDate("I", -1, sysNow, "yyyyMMddHHmmss") + "' AND status != -1")) {
		m.jsAlert("단기간에 많은 게시물을 작성해 등록이 차단되었습니다.\\n잠시 후 다시 시도해주세요.");
		return;
	}

	if(!"".equals(f.get("icode_captcha")) && !f.get("icode").equals(f.get("icode_captcha"))) {
		m.jsAlert(_message.get("alert.common.captcha"));
		return;
	}

	String content = f.get("content1");
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
		m.jsAlert("비속어가 포함되어 등록할 수 없습니다.");
		return;
	}

	int newId = post.getSequence();
	post.item("id", newId);
	post.item("site_id", siteId);
	post.item("board_id", bid);
	post.item("thread", pid == 0 ? post.getLastThread() : pinfo.i("thread"));
	post.item("depth", pid == 0 ? "A" : post.getThreadDepth(pinfo.i("thread"), pinfo.s("depth")));
	post.item("user_id", userId);
	post.item("writer", userName);
	post.item("category_id", pid  == 0 ? f.getInt("category_id") : pinfo.i("category_id"));
	post.item("notice_yn", f.get("notice_yn", "N"));
	post.item("secret_yn", pid == 0 ? f.get("secret_yn", "N") : pinfo.s("secret_yn"));
	post.item("subject", f.get("subject"));
	post.item("youtube_cd", f.get("youtube_cd"));
	post.item("content", content);
	post.item("display_yn", "Y");
	post.item("reg_date", m.time("yyyyMMddHHmmss"));
	post.item("proc_status", 0);
	post.item("status", 1);

	if(!post.insert()) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	//갱신-임시파일
	file.updateTempFile(f.getInt("temp_id"), newId, "post");

	//갱신-파일갯수
	post.updateFileCount(newId);

	//세션초기화
	mSession.put("file_module", "");
	mSession.put("file_module_id", 0);
	mSession.save();

	//관리자메일발송
	p.setVar("board_nm", binfo.s("board_nm"));
	p.setVar("post_subject", f.get("subject"));
	p.setVar("content", content);
	p.setVar("writer", userName);
	p.setVar("login_id", loginId);
	p.setVar("reg_date_conv", _message.get("format.datetime.dot"));

	DataSet adminList = user.find("status = 1 AND id IN ('" + m.replace(binfo.s("admin_idx"), "|", "','") + "')", "id,user_nm,email,mobile");
	while(adminList.next()) {
		p.setVar("board_nm", binfo.s("board_nm"));
		if("Y".equals(siteconfig.s("ktalk_yn"))) {
			ktalkTemplate.sendKtalk(siteinfo, adminList, "newarticle", p);
		} else {
			smsTemplate.sendSms(siteinfo, adminList, "newarticle", p);
		}
		mail.send(siteinfo, adminList, "newarticle", p);
	}

	//이동
	m.jsReplace("read.jsp?id=" + newId + "&" + m.qs("id,pid"), "parent");
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
p.setVar("list_query", m.qs("id,pid"));
p.setVar("form_script", f.getScript());

p.setVar("board", binfo);
p.setVar(pinfo);
p.setVar("post_id", tempId);

p.setVar("reply_block", pid > 0);
p.setLoop("categories", categories);

p.display();

%>