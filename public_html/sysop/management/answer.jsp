<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int pid = m.ri("pid");
int bid = m.ri("bid");
if(pid == 0 || bid == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

//객체
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
UserDao user = new UserDao();
MailDao mail = new MailDao();
SmsDao sms = new SmsDao(siteId);
if(siteinfo.b("sms_yn")) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

//정보-게시판
DataSet binfo = clBoard.find("id = " + bid + " AND status = 1");
if(!binfo.next()) { m.jsError("해당 게시판 정보가 없습니다."); return; }
String btype = binfo.s("board_type");
p.setVar(btype + "_type_block", true);

//정보
DataSet pinfo = clPost.query(
	"SELECT a.*, u.id user_id, u.user_nm, u.mobile, u.email "
	+ " FROM " + clPost.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.id = " + pid + " AND a.status != -1 "
);
if(!pinfo.next()) { m.jsAlert("해당 정보가 없습니다."); return; }

//답변
boolean exists = false;
DataSet info = clPost.find("thread = " + pinfo.s("thread") + " AND depth = 'AA' AND status != -1", "*", "id DESC", 1);
if(!info.next()) {
	int newId = clPost.getSequence();

	clPost.item("id", newId);
	clPost.item("site_id", siteId);
	clPost.item("course_id", courseId);
	clPost.item("board_cd", "qna");
	clPost.item("board_id", bid);
	clPost.item("course_user_id", pinfo.i("course_user_id"));
	clPost.item("thread", pinfo.i("thread"));
	clPost.item("depth", "AA");
	clPost.item("user_id", userId);
	clPost.item("writer", userName);
	clPost.item("subject", pinfo.s("subject"));
	clPost.item("content", "");
	clPost.item("notice_yn", "N");

	clPost.item("mod_date", m.time("yyyyMMddHHmmss"));
	clPost.item("reg_date", m.time("yyyyMMddHHmmss"));
	clPost.item("proc_status", 0);
	clPost.item("status",1);

	if(!clPost.insert()) { m.jsAlert("등록하는 중 오류가 발생하였습니다."); return; }

	info = clPost.find("id = " + newId + "");
	info.next();
}


//폼체크
f.addElement("writer", info.s("writer"), "hname:'작성자', required:'Y'");
f.addElement("content", null, "hname:'답변내용', allowhtml:'Y'");
f.addElement("proc_status", info.s("proc_status"), "hname:'답변상태', required:'Y'");
f.addElement("email_yn", null, "hname:'이메일발송'");
f.addElement("mobile_yn", null, "hname:'SMS발송'");

//등록
if(m.isPost() && f.validate()) {

	String content = f.get("content");
	int bytes = content.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < content.indexOf("<img") && -1 < content.indexOf("data:image/") && -1 < content.indexOf("base64")) {
		m.jsError("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}
	if(60000 < bytes) { m.jsError("내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes + "바이트)"); return; }

	clPost.item("writer", f.get("writer"));
	clPost.item("content", content);

	clPost.item("mod_date", m.time("yyyyMMddHHmmss"));
	clPost.item("proc_status", f.getInt("proc_status"));

	if(!clPost.update("id = " + info.i("id") + "")) { m.jsAlert("수정하는 중 오류가 발생하였습니다."); return; }

	if(-1 == clPost.execute(
			"UPDATE " + clPost.table  + " "
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
			//변수
			String mobile = "";
			mobile = !"".equals(pinfo.s("mobile")) ? pinfo.s("mobile") : "";
			String scontent = "[" + siteinfo.s("site_nm") + "] 질문하신 사항에 답변이 등록되었습니다.";

			if(siteinfo.b("sms_yn") && sms.isMobile(mobile)) {
				//sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));
				sms.send(mobile, siteinfo.s("sms_sender"), scontent, m.time("yyyyMMddHHmmss"));
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
p.setBody("management.answer");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("board", binfo);
p.setVar("parent", pinfo);
p.setVar("post_id", info.i("id"));

p.setLoop("proc_status_list", m.arr2loop(clPost.procStatusList));
p.display();

%>