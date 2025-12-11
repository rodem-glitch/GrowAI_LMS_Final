<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(80, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int pid = m.ri("pid");
if(pid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"ktalk_"});

//객체
UserDao user = new UserDao();
PostLogDao postLog = new PostLogDao(siteId);
PostTemplateDao postTemplate = new PostTemplateDao(siteId);

MailDao mail = new MailDao();
SmsTemplateDao smsTemplate = new SmsTemplateDao(siteId);
KtalkDao ktalk = new KtalkDao(siteId);
if("Y".equals(siteconfig.s("ktalk_yn"))) ktalk.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"), siteconfig.s("ktalk_sender_key"));
KtalkTemplateDao ktalkTemplate = new KtalkTemplateDao(siteId);

//처리
if("template".equals(m.rs("mode"))) {
	//기본키
	int t = m.ri("t");
	if(t == 0) return;

	//postTemplate.d(out);
	out.print(postTemplate.getTemplate(t));
	return;
} else if("assign_del".equals(m.rs("mode"))) {
	if(!postLog.removeAllLog(pid, "assign")) { }
	m.jsReplace("answer.jsp?" + m.qs("mode"), "parent");
	return;
}

//정보
DataSet pinfo = post.query(
	"SELECT a.*, u.user_nm, u.mobile, u.email, pu.id assign_id, pu.user_nm assign_nm, pu.login_id assign_login_id "
	+ " FROM " + post.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " LEFT JOIN " + postLog.table + " pl ON a.id = pl.post_id AND pl.log_type = 'assign' AND pl.site_id = " + siteId + " "
	+ " LEFT JOIN " + user.table + " pu ON pl.user_id = pu.id AND pu.site_id = " + siteId + " "
	+ " WHERE a.id = " + pid + " AND a.status != -1 AND a.site_id = " + siteId + " "
);
if(!pinfo.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

//답변
boolean exists = false;
DataSet info = post.find("thread = " + pinfo.s("thread") + " AND depth = 'AA' AND status != -1", "*", "id DESC", 1);
if(!info.next()) {
	int newId = post.getSequence();

	post.item("id", newId);
	post.item("site_id", siteId);
	post.item("board_id", bid);
	post.item("category_id", pinfo.s("category_id"));
	post.item("thread", pinfo.i("thread"));
	post.item("depth", "AA");
	post.item("user_id", userId);
	post.item("writer", userName);
	post.item("subject", pinfo.s("subject"));
	post.item("content", "");
	post.item("notice_yn", "N");

	post.item("reg_date", m.time("yyyyMMddHHmmss"));
	post.item("proc_status", 0);
	post.item("status",1);

	if(!post.insert()) { m.jsAlert("등록하는 중 오류가 발생하였습니다."); return; }

	info = post.find("id = " + newId + "");
	info.next();
}


//폼체크
f.addElement("writer", info.s("writer"), "hname:'작성자', required:'Y'");
f.addElement("content", null, "hname:'답변내용', allowhtml:'Y'");
f.addElement("proc_status", info.s("proc_status"), "hname:'답변상태', required:'Y'");
f.addElement("email_yn", "Y", "hname:'이메일발송'");
f.addElement("mobile_yn", "Y", "hname:'SMS발송'");

//등록
if(m.isPost() && f.validate()) {

	String content = f.get("content1");
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsError("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}
	if(60000 < bytes) { m.jsError("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)"); return; }
	
	//제한-비속어
	if(wordFilterDao.check(content)) {
		m.jsAlert("비속어가 포함되어 수정할 수 없습니다.");
		return;
	}

	post.item("writer", f.get("writer"));
	post.item("content", content);

	post.item("mod_date", m.time("yyyyMMddHHmmss"));
	post.item("proc_status", f.getInt("proc_status"));

	if(!post.update("id = " + info.i("id") + "")) { m.jsAlert("수정하는 중 오류가 발생하였습니다."); return; }

	if(-1 == post.execute(
			"UPDATE " + post.table  + " "
			+ " SET proc_status = " + f.getInt("proc_status") + " "
			+ " WHERE id = " + pid + " "
	)) {
		m.jsAlert("수정하는 중 오류가 발생하였습니다."); return;
	}

	//답변완료
	if(f.getInt("proc_status") == 1) {
		//메일
		if("Y".equals(f.get("email_yn"))) {
			pinfo.put("id", pinfo.s("user_id"));
			p.setVar("content", content);
			p.setVar("pinfo", pinfo);
			mail.send(siteinfo, pinfo, "qna_answer", p);
		}

		//SMS
		if("Y".equals(f.get("mobile_yn"))) {
			pinfo.put("id", pinfo.s("user_id"));
			p.setVar("pinfo", pinfo);
			if("Y".equals(siteconfig.s("ktalk_yn"))) {
				p.setVar("user_nm", pinfo.s("writer"));
				p.setVar("writer", pinfo.s("writer"));
				p.setVar("subject", pinfo.s("subject"));
				ktalkTemplate.sendKtalk(siteinfo, pinfo, "qna_answer", p);
			} else {
				smsTemplate.sendSms(siteinfo, pinfo, "qna_answer", p);
			}
		}

	}

	//이동
	m.jsReplace("answer.jsp?" + m.qs());
	return;
}

//포멧팅
info.put("mod_date_conv", info.i("proc_status") == 1 ? m.time("yyyy.MM.dd HH:mm", info.s("mod_date")) : "-");
pinfo.put("mobile_conv", !"".equals(pinfo.s("mobile")) ? pinfo.s("mobile") : "-" );

//출력
p.setLayout("blank");
p.setBody("board.answer");
p.setVar("p_title", binfo.s("board_nm"));
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("board", binfo);
p.setVar("parent", pinfo);
p.setVar("post_id", info.i("id"));

p.setLoop("template_list", postTemplate.getTemplateList(binfo.i("id")));
p.setLoop("proc_status_list", m.arr2loop(post.procStatusList));
p.display();

%>