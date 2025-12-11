<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
SmsDao sms = new SmsDao(siteId);
boolean isSend = siteinfo.b("sms_yn");
if(isSend) sms.setAccount(siteinfo.s("sms_id"), siteinfo.s("sms_pw"));

//제한
if(!isSend) { m.jsAlert("SMS 서비스를 신청하셔야 이용할 수 있습니다."); m.js("parent.CloseLayer();"); return; }

//기본키
String fid = m.rs("fid");
if("".equals(fid)) {
	m.jsAlert("기본키는 반드시 지정해야 합니다.");
	m.js("parent.CloseLayer();");
	return;
}

//객체
SmsUserDao smsUser = new SmsUserDao();
UserDao user = new UserDao();
FormmailDao formmail = new FormmailDao();

//정보-회원
DataSet uinfo = user.find("id = " + userId + "");
if(!uinfo.next()) { m.jsAlert("해당 회원 정보가 없습니다."); m.js("parent.CloseLayer();"); return; }
String mobile = "";
mobile = !"".equals(uinfo.s("mobile")) ? uinfo.s("mobile") : "";

//폼체크
f.addElement("sender", siteinfo.s("sms_sender"), "hname:'발신번호', required:'Y'");
f.addElement("content", null, "hname:'내용', required:'Y'");
f.addElement("reservation_yn", null, "hname:'발송시기'");
f.addElement("send_date", m.time("yyyy-MM-dd"), "hname:'발송시기'");
f.addElement("send_hour", m.time("HH"), "hname:'발송시기'");
f.addElement("send_minute", m.time("mm"), "hname:'발송시기'");

//정보-폼메일
DataSet finfo = formmail.query(
	"SELECT a.*"
	+ " FROM " + formmail.table + " a"
	+ " WHERE a.id = " + fid + " AND (a.mobile IS NOT NULL OR a.mobile != '')"
	, 1
);
while(finfo.next()) {
	finfo.put("s_value", !"".equals(finfo.s("mobile")) ? "(" + finfo.s("mobile") + ")" : "(-)" );
}

//기록-개인정보조회
if(finfo.size() > 0 && !isBlindUser) _log.add("V", "게시판목록", finfo.size(), "이러닝 운영", finfo);

//등록
if(m.isPost() && f.validate()) {

	//변수
	String sendDate = "Y".equals(f.get("reservation_yn")) ? m.time("yyyyMMdd", f.get("send_date")) + f.get("send_hour") + f.get("send_minute") + "59" : null;

	int newId = sms.getSequence();

	sms.item("id", newId);
	sms.item("site_id", siteId);

	sms.item("module", "user");
	sms.item("module_id", 0);
	sms.item("user_id", userId);
	sms.item("sender", f.get("sender"));
	sms.item("content", f.get("content"));
	sms.item("resend_id", 0);
	sms.item("send_cnt", 0);
	sms.item("fail_cnt", 0);
	sms.item("send_date", "Y".equals(f.get("reservation_yn")) ? sendDate : m.time("yyyyMMddHHmmss"));
	sms.item("reg_date", m.time("yyyyMMddHHmmss"));
	sms.item("status", 1);

	if(!sms.insert()) {
		m.jsAlert("등록하는 중 오류가 발생했습니다.");
		m.js("parent.CloseLayer();");
		return;
	}

	//SMS 발송
	int sendCnt = 0;
	int failCnt = 0;
	finfo.first();
	while(finfo.next()) {
		mobile = "";
		mobile = !"".equals(finfo.s("mobile")) ? finfo.s("mobile") : "";
		smsUser.item("site_id", siteId);
		smsUser.item("sms_id", newId);
		smsUser.item("mobile", finfo.s("mobile"));
		smsUser.item("user_id", -99);
		smsUser.item("user_nm", finfo.s("user_nm"));
		if(sms.isMobile(mobile)) {
			smsUser.item("send_yn", "Y");
			if(smsUser.insert()) {
				if(isSend) sms.send(mobile, f.get("sender"), f.get("content"), sendDate);
				sendCnt++;
			}
		} else {
			smsUser.item("send_yn", "N");
			if(smsUser.insert()) { failCnt++; }
		}
	}

	//발송건수
	sms.execute("UPDATE " + sms.table + " SET send_cnt = " + sendCnt + ", fail_cnt = " + failCnt + " WHERE id = " + newId);

	m.jsAlert("발송되었습니다.");
	m.js("parent.CloseLayer();");
	return;
}

//출력
p.setLayout("poplayer");
p.setBody("formmail.pop_sms");
p.setVar("p_title", "SMS발송");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(finfo);

p.setVar("is_send", isSend);
p.setLoop("hours", sms.getHours());
p.setLoop("minutes", sms.getMinutes());
p.display();

%>