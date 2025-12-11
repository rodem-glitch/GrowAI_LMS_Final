<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
String code = m.rs("code");
if("".equals(code)) { m.jsError(_message.get("alert.common.required_key")); return; }

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"ktalk_"});

//객체
ClBoardDao board = new ClBoardDao();
ClPostDao post = new ClPostDao();
ClFileDao file = new ClFileDao();
CourseManagerDao courseManager = new CourseManagerDao();
MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
KtalkDao ktalk = new KtalkDao(siteId);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId);
WordFilterDao wordFilterDao = new WordFilterDao();

//정보-게시판
DataSet binfo = board.find("course_id = " + courseId + " AND code = '" + code + "' AND status = 1");
if(!binfo.next()) { m.jsError(_message.get("alert.board.nodata")); return; }
if(!binfo.b("write_yn")) { m.jsError(_message.get("alert.common.permission_insert")); return; }
String btype = binfo.s("board_type");
int bid = binfo.i("id");
binfo.put("type_" + btype, true);
binfo.put("code_" + code, true);

//아이디
int pid = m.ri("pid");

//정보-이전글
DataSet pinfo = new DataSet();
String subject = "";
//String content = "";
String permitId = "";
if(pid  > 0) {
	//정보
	pinfo = post.find("id = " + pid + "");
	if(!pinfo.next()) { m.jsError(_message.get("alert.post.nodata_parent"));	return;  }
	pinfo.put("subject", "[RE] " + pinfo.s("subject"));
	pinfo.put("content", "<br><br><br><p style='margin:20px 0 10px 0'>[원문내용] " + m.repeatString("----", 20) + "</p>" + pinfo.s("content"));
}

//폼체크
f.addElement("subject", pinfo.s("subject"), "hname:'제목', required:'Y'");
f.addElement("secret_yn", null, "hname:'비밀글 여부'" + ("qna".equals(code) ? ", checked:'Y'" : ""));
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");
if("recomm".equals(btype)) f.addElement("point", null, "hname:'점수', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	//제한-글작성수
	if(2 < post.findCount("site_id = " + siteId + " AND user_id = " + userId + " AND reg_date >= '" + m.addDate("I", -5, sysNow, "yyyyMMddHHmmss") + "' AND status != -1")) {
		m.jsAlert("단기간에 많은 게시물을 작성해 등록이 차단되었습니다.\\n잠시 후 다시 시도해주세요.");
		return;
	}

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
		m.jsAlert("비속어가 포함되어 등록할 수 없습니다.");
		return;
	}

	int newId = post.getSequence();
	post.item("id", newId);
	post.item("site_id", siteId);
	post.item("course_id", courseId);
	post.item("course_user_id", cuid);
	post.item("board_cd", binfo.s("code"));
	post.item("board_id", bid);
	post.item("thread", pid == 0 ? post.getLastThread() : pinfo.i("thread"));
	post.item("depth", pid == 0 ? "A" : post.getThreadDepth(pinfo.i("thread"), pinfo.s("depth")));
	post.item("user_id", userId);
	post.item("writer", userName);
	post.item("notice_yn", f.get("notice_yn", "N"));
	post.item("secret_yn", pid  == 0 ? f.get("secret_yn", "N") : pinfo.s("secret_yn"));
	post.item("subject", f.get("subject"));
	post.item("content", content);
	post.item("point", f.getInt("point"));
	post.item("hit_cnt", 0);
	post.item("comm_cnt", 0);
	post.item("display_yn", "Y");
	post.item("proc_status", 0);
	post.item("reg_date", m.time("yyyyMMddHHmmss"));
	post.item("status", 1);
	post.item("upload_file_key", f.get("upload_file_key"));
	if(!post.insert()) { m.jsAlert(_message.get("alert.common.error_insert")); return; }

	//갱신-임시파일
	file.updateTempFile(f.getInt("temp_id"), newId, "post");

	if("qna".equals(btype)) {
		File f1 = f.saveFile("question_file");
		if(f1 != null) {
			file.item("site_id", siteId);
			file.item("module", "post");
			file.item("module_id", newId);
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
	post.updateFileCount(newId);

	//관리자메일발송
	p.setVar("board_nm", cinfo.s("course_nm") + " 과정 " + binfo.s("board_nm"));
	p.setVar("post_subject", f.get("subject"));
	p.setVar("content", content);
	p.setVar("writer", userName);
	p.setVar("login_id", loginId);
	p.setVar("reg_date_conv", m.time(_message.get("format.datetime.dot")));

	DataSet adminList = courseManager.query(
		" SELECT u.id, u.user_nm, u.email, u.mobile "
		+ " FROM " + courseManager.table + " a "
		+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " AND u.status != -1 "
		+ " WHERE a.course_id = " + courseId
	);
	while(adminList.next()) {
		if("Y".equals(siteconfig.s("ktalk_yn"))) {
			ktalkTemplate.sendKtalk(siteinfo, adminList, "newarticle", p);
		} else {
			smsTemplate.sendSms(siteinfo, adminList, "newarticle", p);
		}
		mail.send(siteinfo, adminList, "newarticle", p);
	}

	//이동
	m.jsReplace("cpost_list.jsp?" + m.qs("pid"), "parent");
	return;
}

//출력
p.setLayout(ch);
p.setBody("classroom.cwrite");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,pid"));
p.setVar("form_script", f.getScript());

p.setVar("board", binfo);
p.setVar(pinfo);
p.setVar("post_id", m.getRandInt(-2000000, 1990000));

p.setVar("reply_block", pid > 0);
p.setVar("active_" + code, "select");
p.setVar("kollus_upload_block", !"".equals(SiteConfig.s("kollus_clpost_key")));
p.display();

%>